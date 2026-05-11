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

struct Args {
    repo: Option<PathBuf>,
    nixparserlean_dir: Option<PathBuf>,
    only_nixparserlean_interop: bool,
}

struct InteropCase {
    name: &'static str,
    render_arg: &'static str,
    source_arg: bool,
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

fn run_quiet(repo: &Path, program: &str, args: &[&str]) -> Result<(), String> {
    eprintln!("running: {} {}", program, args.join(" "));
    let status = Command::new(program)
        .args(args)
        .current_dir(repo)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
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
    run(
        repo,
        "lake",
        &["exe", "leanix", "verify-artifact", artifact_dir],
    )?;
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "verify-artifact",
            "examples/proof-carrying-cli-closure/artifact",
        ],
    )?;
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

fn run_interop_case(
    repo: &Path,
    nixparserlean_dir: &Path,
    out_dir: &Path,
    case: &InteropCase,
) -> Result<(), String> {
    let output = out_dir.join(format!("{}.flake.nix", case.name));
    let output_arg = output.to_string_lossy().into_owned();
    let source = format!("path:{}", repo.display());

    eprintln!("interop render: {}", case.name);
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
                &output_arg,
            ],
        )?;
    } else {
        run(
            repo,
            "lake",
            &["exe", "leanix", case.render_arg, "--out", &output_arg],
        )?;
    }

    eprintln!("interop desugar: {}", case.name);
    run_quiet(
        nixparserlean_dir,
        "nix",
        &[
            "develop",
            "--command",
            "lake",
            "exe",
            "nixparserlean",
            "--desugar",
            "--file",
            &output_arg,
        ],
    )?;

    eprintln!("interop eval: {}", case.name);
    run_quiet(
        nixparserlean_dir,
        "nix",
        &[
            "develop",
            "--command",
            "lake",
            "exe",
            "nixparserlean",
            "--eval",
            "--file",
            &output_arg,
        ],
    )?;

    Ok(())
}

fn run_nixparserlean_interop(repo: &Path, nixparserlean_dir: &Path) -> Result<(), String> {
    eprintln!("case: nixparserlean interop");
    if !nixparserlean_dir.join("lakefile.lean").is_file()
        || !nixparserlean_dir.join("NixParserLean").is_dir()
    {
        return Err(format!(
            "nixparserlean path '{}' is not a nixparserlean checkout; expected lakefile.lean and NixParserLean/",
            nixparserlean_dir.display()
        ));
    }

    let out_dir = repo.join("generated/interop-nixparserlean");
    fs::create_dir_all(&out_dir)
        .map_err(|err| format!("failed creating {}: {err}", out_dir.display()))?;

    let cases = [
        InteropCase {
            name: "hello",
            render_arg: "render-example",
            source_arg: false,
        },
        InteropCase {
            name: "closure",
            render_arg: "render-closure",
            source_arg: false,
        },
        InteropCase {
            name: "cli-schema",
            render_arg: "render-cli-schema",
            source_arg: false,
        },
        InteropCase {
            name: "showcase",
            render_arg: "render-showcase",
            source_arg: false,
        },
        InteropCase {
            name: "self",
            render_arg: "render-self",
            source_arg: true,
        },
    ];

    for case in cases {
        run_interop_case(repo, nixparserlean_dir, &out_dir, &case)?;
    }

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
    "usage: leanix-e2e-runner [--repo PATH] [--nixparserlean-dir PATH] [--only-nixparserlean-interop]\n       leanix-e2e-runner --help"
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

fn parse_args() -> Result<Args, String> {
    let args: Vec<String> = env::args().skip(1).collect();
    let mut repo = None;
    let mut nixparserlean_dir = None;
    let mut only_nixparserlean_interop = false;
    let mut index = 0usize;

    while index < args.len() {
        match args[index].as_str() {
            "--help" | "-h" => {
                println!("{}", usage());
                std::process::exit(0);
            }
            "--repo" => {
                index += 1;
                let path = args
                    .get(index)
                    .ok_or_else(|| format!("{}\n--repo requires PATH", usage()))?;
                repo = Some(absolute_path(Path::new(path))?);
            }
            "--nixparserlean-dir" => {
                index += 1;
                let path = args
                    .get(index)
                    .ok_or_else(|| format!("{}\n--nixparserlean-dir requires PATH", usage()))?;
                nixparserlean_dir = Some(absolute_path(Path::new(path))?);
            }
            "--only-nixparserlean-interop" => {
                only_nixparserlean_interop = true;
            }
            unknown => {
                return Err(format!("{}\nunknown argument: {}", usage(), unknown));
            }
        }
        index += 1;
    }

    Ok(Args {
        repo,
        nixparserlean_dir,
        only_nixparserlean_interop,
    })
}

fn repo_root(explicit: Option<PathBuf>) -> Result<PathBuf, String> {
    if let Some(explicit) = explicit {
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

fn configured_nixparserlean_dir(explicit: Option<PathBuf>) -> Result<Option<PathBuf>, String> {
    if explicit.is_some() {
        return Ok(explicit);
    }

    match env::var_os("NIXPARSERLEAN_DIR") {
        Some(path) => absolute_path(Path::new(&path)).map(Some),
        None => Ok(None),
    }
}

fn main() -> Result<(), String> {
    let args = parse_args()?;
    let repo = repo_root(args.repo)?;
    let nixparserlean_dir = configured_nixparserlean_dir(args.nixparserlean_dir)?;

    if args.only_nixparserlean_interop {
        let nixparserlean_dir = nixparserlean_dir.ok_or_else(|| {
            "--only-nixparserlean-interop requires --nixparserlean-dir PATH or NIXPARSERLEAN_DIR"
                .to_string()
        })?;
        run_nixparserlean_interop(&repo, &nixparserlean_dir)?;
        eprintln!("e2e: all cases passed");
        return Ok(());
    }

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

    match nixparserlean_dir {
        Some(nixparserlean_dir) => run_nixparserlean_interop(&repo, &nixparserlean_dir)?,
        None => eprintln!(
            "case: nixparserlean interop (skipped; pass --nixparserlean-dir PATH or set NIXPARSERLEAN_DIR)"
        ),
    }

    eprintln!("e2e: all cases passed");
    Ok(())
}
