use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

struct Case {
    name: &'static str,
    render_arg: &'static str,
    source_arg: bool,
    lean_source: Option<&'static str>,
    golden: Option<&'static str>,
}

struct InvalidCase {
    name: &'static str,
    render_arg: &'static str,
    expected_stderr: &'static str,
}

fn run(repo: &Path, program: &str, args: &[&str]) -> Result<(), String> {
    eprintln!("running: {} {}", program, args.join(" "));
    let status = Command::new(program)
        .args(args)
        .current_dir(repo)
        .stdin(Stdio::null())
        .status()
        .map_err(|err| format!("failed to start {program}: {err}"))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("{program} exited with {status}"))
    }
}

fn run_case(repo: &Path, case: &Case) -> Result<(), String> {
    let output = "generated/flake.nix";
    let source = format!("path:{}", repo.display());

    if let Some(source) = case.lean_source {
        run(repo, "lake", &["env", "lean", source])?;
    }

    if case.source_arg {
        run(
            repo,
            "lake",
            &[
                "exe",
                "leanix",
                case.render_arg,
                "--source",
                &source,
                "--out",
                output,
            ],
        )?;
    } else {
        run(
            repo,
            "lake",
            &["exe", "leanix", case.render_arg, "--out", output],
        )?;
    }

    if let Some(golden) = case.golden {
        let generated = fs::read_to_string(repo.join(output))
            .map_err(|err| format!("failed reading generated output: {err}"))?;
        let expected = fs::read_to_string(repo.join(golden))
            .map_err(|err| format!("failed reading golden output {golden}: {err}"))?;
        if generated != expected {
            return Err(format!("generated output differs from {golden}"));
        }
    }

    run(repo, "nix", &["flake", "check", "path:./generated"])?;

    Ok(())
}

fn compare_file(repo: &Path, actual: &str, expected: &str) -> Result<(), String> {
    let actual_text = fs::read_to_string(repo.join(actual))
        .map_err(|err| format!("failed reading {actual}: {err}"))?;
    let expected_text = fs::read_to_string(repo.join(expected))
        .map_err(|err| format!("failed reading {expected}: {err}"))?;
    if actual_text == expected_text {
        Ok(())
    } else {
        Err(format!("{actual} differs from {expected}"))
    }
}

fn extract_json_section<'a>(manifest: &'a str, field: &str) -> Result<&'a str, String> {
    let marker = format!("\"{}\":", field);
    let marker_index = manifest
        .find(&marker)
        .ok_or_else(|| format!("manifest missing field '{field}'"))?;
    let after_marker = &manifest[marker_index + marker.len()..];
    let bracket_offset = after_marker
        .find('[')
        .ok_or_else(|| format!("manifest field '{field}' is not an array"))?;
    let section_start = marker_index + marker.len() + bracket_offset;
    let mut depth = 0usize;
    let mut in_string = false;
    let mut escaped = false;

    for (offset, ch) in manifest[section_start..].char_indices() {
        if in_string {
            if escaped {
                escaped = false;
            } else if ch == '\\' {
                escaped = true;
            } else if ch == '"' {
                in_string = false;
            }
            continue;
        }

        match ch {
            '"' => in_string = true,
            '[' => depth += 1,
            ']' => {
                depth -= 1;
                if depth == 0 {
                    let inner_start = section_start + 1;
                    let inner_end = section_start + offset;
                    return Ok(&manifest[inner_start..inner_end]);
                }
            }
            _ => {}
        }
    }

    Err(format!("manifest field '{field}' has no closing array"))
}

fn extract_json_strings(section: &str) -> Vec<String> {
    let mut values = Vec::new();
    let mut current = String::new();
    let mut in_string = false;
    let mut escaped = false;

    for ch in section.chars() {
        if in_string {
            if escaped {
                current.push(ch);
                escaped = false;
            } else if ch == '\\' {
                escaped = true;
            } else if ch == '"' {
                values.push(current.clone());
                current.clear();
                in_string = false;
            } else {
                current.push(ch);
            }
        } else if ch == '"' {
            in_string = true;
        }
    }

    values
}

fn extract_object_string_values(section: &str, field: &str) -> Vec<String> {
    let strings = extract_json_strings(section);
    let mut values = Vec::new();
    let mut iter = strings.iter();

    while let Some(item) = iter.next() {
        if item == field {
            if let Some(value) = iter.next() {
                values.push(value.clone());
            }
        }
    }

    values
}

fn require_contains(values: &[String], expected: &str, context: &str) -> Result<(), String> {
    if values.iter().any(|value| value == expected) {
        Ok(())
    } else {
        Err(format!("{context} missing '{expected}'"))
    }
}

fn verify_artifact_manifest(repo: &Path, artifact_dir: &str) -> Result<(), String> {
    let artifact_path = repo.join(artifact_dir);
    let manifest = fs::read_to_string(artifact_path.join("leanix.manifest.json"))
        .map_err(|err| format!("failed reading artifact manifest: {err}"))?;
    let flake = fs::read_to_string(artifact_path.join("flake.nix"))
        .map_err(|err| format!("failed reading artifact flake: {err}"))?;

    let generated_files = extract_json_strings(extract_json_section(&manifest, "generatedFiles")?);
    for file in &generated_files {
        if !artifact_path.join(file).is_file() {
            return Err(format!("manifest generated file '{file}' is missing"));
        }
    }

    let systems = extract_json_strings(extract_json_section(&manifest, "systems")?);
    require_contains(&systems, "x86_64-linux", "manifest systems")?;

    let input_trust_classes =
        extract_object_string_values(extract_json_section(&manifest, "inputs")?, "trustClass");
    require_contains(
        &input_trust_classes,
        "lockfile-backed-flake-input",
        "manifest input trust classes",
    )?;

    let package_section = extract_json_section(&manifest, "packages")?;
    let packages = extract_object_string_values(package_section, "name");
    require_contains(&packages, "helloWrapper", "manifest packages")?;
    require_contains(&packages, "helloTool", "manifest packages")?;
    for package in &packages {
        let package_line = format!("        \"{}\" =", package);
        if !flake.contains(&package_line) {
            return Err(format!(
                "manifest package '{package}' is missing from artifact flake"
            ));
        }
    }

    for section in ["apps", "checks"] {
        let references =
            extract_object_string_values(extract_json_section(&manifest, section)?, "packageName");
        for package in references {
            if !packages.contains(&package) {
                return Err(format!(
                    "manifest {section} reference points at undeclared package '{package}'"
                ));
            }
        }
    }

    let invariants = extract_json_strings(extract_json_section(&manifest, "checkedInvariants")?);
    for invariant in [
        "PackageClosure.refsResolve",
        "PackageClosure.acyclicByFuel",
        "CliProject.appPointsAtPackage",
        "sourceTrust.fetchLikeSourcesRequireHash",
    ] {
        require_contains(&invariants, invariant, "manifest checked invariants")?;
    }

    Ok(())
}

fn run_artifact_case(repo: &Path) -> Result<(), String> {
    let artifact_dir = "generated/showcase-artifact";
    eprintln!("case: proof-carrying flake artifact");
    run(
        repo,
        "lake",
        &["exe", "leanix", "emit-artifact", "--out", artifact_dir],
    )?;
    compare_file(
        repo,
        "generated/showcase-artifact/flake.nix",
        "examples/proof-carrying-cli-closure/artifact/flake.nix",
    )?;
    compare_file(
        repo,
        "generated/showcase-artifact/leanix.manifest.json",
        "examples/proof-carrying-cli-closure/artifact/leanix.manifest.json",
    )?;
    verify_artifact_manifest(repo, artifact_dir)?;
    run(
        repo,
        "nix",
        &["flake", "check", "path:./generated/showcase-artifact"],
    )?;
    Ok(())
}

fn run_source_injection_case(repo: &Path) -> Result<(), String> {
    let output = "generated/source-injection-flake.nix";
    eprintln!("case: source argument escaping");
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "render-self",
            "--source",
            "path:/x\";a=\"b",
            "--out",
            output,
        ],
    )?;
    let rendered = fs::read_to_string(repo.join(output))
        .map_err(|err| format!("failed reading source injection output: {err}"))?;
    if rendered.contains("a = \"b\"") {
        Err("source argument injected an undeclared input attr".to_string())
    } else if rendered.contains("path:/x\\\";a=\\\"b") {
        Ok(())
    } else {
        Err("source argument was not visibly escaped in rendered flake".to_string())
    }
}

fn run_hashed_source_case(repo: &Path) -> Result<(), String> {
    let output = "generated/flake.nix";
    let source = format!("path:{}", repo.join("e2e/source-fixture").display());
    eprintln!("case: hashed source input");
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "render-hashed-source",
            "--source",
            &source,
            "--out",
            output,
        ],
    )?;
    let rendered = fs::read_to_string(repo.join(output))
        .map_err(|err| format!("failed reading hashed source output: {err}"))?;
    for expected in [
        "type = \"path\";",
        "narHash = \"sha256-jsgXtBABq0OCdKEeY0mS7yzxEAn4GAJgw7zldbIgGGw=\";",
        "fixtureSrc = (builtins.fetchTree",
    ] {
        if !rendered.contains(expected) {
            return Err(format!("hashed source output missing '{expected}'"));
        }
    }
    run(repo, "nix", &["flake", "check", "path:./generated"])?;
    Ok(())
}

fn run_invalid_case(repo: &Path, case: &InvalidCase) -> Result<(), String> {
    let output = "generated/invalid-flake.nix";
    eprintln!("case: {}", case.name);

    let output = Command::new("lake")
        .args(["exe", "leanix", case.render_arg, "--out", output])
        .current_dir(repo)
        .stdin(Stdio::null())
        .output()
        .map_err(|err| format!("failed to start lake: {err}"))?;

    if output.status.success() {
        Err(format!(
            "invalid case '{}' unexpectedly rendered successfully",
            case.name
        ))
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        let actual = stderr.trim();
        if actual == case.expected_stderr {
            Ok(())
        } else {
            Err(format!(
                "invalid case '{}' stderr mismatch\nexpected: {}\nactual: {}",
                case.name, case.expected_stderr, actual
            ))
        }
    }
}

fn usage() -> &'static str {
    "usage: leanix-e2e-runner [--repo PATH]\n       leanix-e2e-runner --help"
}

fn is_repo_root(path: &Path) -> bool {
    path.join("lakefile.lean").is_file() && path.join("e2e/runner/Cargo.toml").is_file()
}

fn find_repo_root(start: &Path) -> Option<PathBuf> {
    let mut candidate = start.to_path_buf();
    loop {
        if is_repo_root(&candidate) {
            return Some(candidate);
        }
        if !candidate.pop() {
            return None;
        }
    }
}

fn absolute_path(path: &Path) -> Result<PathBuf, String> {
    if path.is_absolute() {
        Ok(path.to_path_buf())
    } else {
        env::current_dir()
            .map_err(|err| format!("failed to read current directory: {err}"))
            .map(|cwd| cwd.join(path))
    }
}

fn parse_repo_arg() -> Result<Option<PathBuf>, String> {
    let args: Vec<String> = env::args().skip(1).collect();
    match args.as_slice() {
        [] => Ok(None),
        [flag] if flag == "--help" || flag == "-h" => {
            println!("{}", usage());
            std::process::exit(0);
        }
        [flag, path] if flag == "--repo" => absolute_path(Path::new(path)).map(Some),
        _ => Err(format!(
            "{}\nunknown arguments: {}",
            usage(),
            args.join(" ")
        )),
    }
}

fn repo_root() -> Result<PathBuf, String> {
    if let Some(explicit) = parse_repo_arg()? {
        if is_repo_root(&explicit) {
            return Ok(explicit);
        }
        return Err(format!(
            "--repo path '{}' is not a Leanix repository root; expected lakefile.lean and e2e/runner/Cargo.toml",
            explicit.display()
        ));
    }

    let current =
        env::current_dir().map_err(|err| format!("failed to read current directory: {err}"))?;
    find_repo_root(&current).ok_or_else(|| {
        format!(
            "could not find Leanix repository root from '{}'; expected lakefile.lean and e2e/runner/Cargo.toml in this directory or a parent",
            current.display()
        )
    })
}

fn main() -> Result<(), String> {
    let repo = repo_root()?;
    let cases = [
        Case {
            name: "typed hello flake",
            render_arg: "render-example",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/hello.flake.nix"),
        },
        Case {
            name: "self flake",
            render_arg: "render-self",
            source_arg: true,
            lean_source: None,
            golden: None,
        },
        Case {
            name: "typed closure flake",
            render_arg: "render-closure",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/closure.flake.nix"),
        },
        Case {
            name: "typed CLI schema flake",
            render_arg: "render-cli-schema",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/cli-schema.flake.nix"),
        },
        Case {
            name: "proof-carrying CLI closure showcase",
            render_arg: "render-showcase",
            source_arg: false,
            lean_source: Some("examples/proof-carrying-cli-closure/source.lean"),
            golden: Some("examples/proof-carrying-cli-closure/expected.flake.nix"),
        },
        Case {
            name: "renderer escaping flake",
            render_arg: "render-escaping",
            source_arg: false,
            lean_source: None,
            golden: None,
        },
        Case {
            name: "multi-system renderer flake",
            render_arg: "render-multi-system",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/multi-system.flake.nix"),
        },
        Case {
            name: "pinned flake input",
            render_arg: "render-pinned-inputs",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/pinned-inputs.flake.nix"),
        },
        Case {
            name: "env var rendering",
            render_arg: "render-env",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/env.flake.nix"),
        },
    ];
    let invalid_cases = [
        InvalidCase {
            name: "missing package reference",
            render_arg: "render-invalid-missing-ref",
            expected_stderr: "error: package broken for x86_64-linux refers to missing package missing",
        },
        InvalidCase {
            name: "package dependency cycle",
            render_arg: "render-invalid-cycle",
            expected_stderr:
                "error: package dependency cycle for x86_64-linux: cycleA reaches itself through cycleB",
        },
        InvalidCase {
            name: "typed build text missing package reference",
            render_arg: "render-invalid-typed-text-ref",
            expected_stderr:
                "error: package typedTextBroken for x86_64-linux refers to missing package missingTextDep",
        },
        InvalidCase {
            name: "duplicate package env",
            render_arg: "render-invalid-duplicate-package-env",
            expected_stderr:
                "error: duplicate env var names for package duplicatePackageEnv on x86_64-linux",
        },
        InvalidCase {
            name: "duplicate dev shell env",
            render_arg: "render-invalid-duplicate-shell-env",
            expected_stderr: "error: duplicate env var names for devShell dupShell on x86_64-linux",
        },
        InvalidCase {
            name: "unsupported package env builder",
            render_arg: "render-invalid-unsupported-env-builder",
            expected_stderr:
                "error: package unsupportedEnv for x86_64-linux can only set env vars on runCommand or runSteps builders",
        },
        InvalidCase {
            name: "invalid CLI schema",
            render_arg: "render-invalid-cli-schema",
            expected_stderr: "error: CliProject app must point at the project package",
        },
        InvalidCase {
            name: "source input missing hash",
            render_arg: "render-invalid-source-missing-hash",
            expected_stderr: "error: source input unhashedSrc must have a narHash",
        },
    ];

    for case in cases {
        eprintln!("case: {}", case.name);
        run_case(&repo, &case)?;
    }

    run_artifact_case(&repo)?;
    run_source_injection_case(&repo)?;
    run_hashed_source_case(&repo)?;

    for case in invalid_cases {
        run_invalid_case(&repo, &case)?;
    }

    eprintln!("e2e: all cases passed");
    Ok(())
}
