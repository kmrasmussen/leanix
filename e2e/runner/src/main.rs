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
    parsed_contract: Option<ParsedOutputContract>,
}

#[derive(Clone, Copy)]
struct ParsedOutputContract {
    systems: &'static [&'static str],
    packages: &'static [&'static str],
    apps: &'static [&'static str],
    dev_shells: &'static [&'static str],
    checks: &'static [&'static str],
    default_package_targets: &'static [&'static str],
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

fn run_capture(repo: &Path, program: &str, args: &[&str]) -> Result<String, String> {
    eprintln!("running: {} {}", program, args.join(" "));
    let output = Command::new(program)
        .args(args)
        .current_dir(repo)
        .stdin(Stdio::null())
        .output()
        .map_err(|err| format!("failed to start {program}: {err}"))?;

    if output.status.success() {
        String::from_utf8(output.stdout)
            .map_err(|err| format!("{program} produced non-UTF-8 output: {err}"))
    } else {
        Err(format!(
            "{program} exited with {}\n{}",
            output.status,
            String::from_utf8_lossy(&output.stderr)
        ))
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

fn expect_verify_artifact_failure(
    repo: &Path,
    artifact_dir: &str,
    expected_stderr: &str,
) -> Result<(), String> {
    let output = Command::new("lake")
        .args(["exe", "leanix", "verify-artifact", artifact_dir])
        .current_dir(repo)
        .stdin(Stdio::null())
        .output()
        .map_err(|err| format!("failed to start lake: {err}"))?;

    if output.status.success() {
        return Err(format!("{artifact_dir} unexpectedly verified"));
    }

    let stderr = String::from_utf8_lossy(&output.stderr);
    let actual = stderr.trim();
    if actual == expected_stderr {
        Ok(())
    } else {
        Err(format!(
            "artifact verifier stderr mismatch\nexpected: {expected_stderr}\nactual: {actual}"
        ))
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

    let tampered_artifact_dir = "generated/tampered-artifact";
    eprintln!("case: artifact tamper rejection");
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "emit-artifact",
            "--out",
            tampered_artifact_dir,
        ],
    )?;
    let tampered_flake_path = repo.join(tampered_artifact_dir).join("flake.nix");
    let mut tampered_flake = fs::read_to_string(&tampered_flake_path)
        .map_err(|err| format!("failed reading {}: {err}", tampered_flake_path.display()))?;
    tampered_flake.push_str("\n# tampered\n");
    fs::write(&tampered_flake_path, tampered_flake)
        .map_err(|err| format!("failed writing {}: {err}", tampered_flake_path.display()))?;
    expect_verify_artifact_failure(
        repo,
        tampered_artifact_dir,
        "error: artifact file hash mismatch: flake.nix",
    )?;

    let missing_file_artifact_dir = "generated/missing-file-artifact";
    eprintln!("case: artifact missing generated file rejection");
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "emit-artifact",
            "--out",
            missing_file_artifact_dir,
        ],
    )?;
    let missing_flake_path = repo.join(missing_file_artifact_dir).join("flake.nix");
    fs::remove_file(&missing_flake_path)
        .map_err(|err| format!("failed removing {}: {err}", missing_flake_path.display()))?;
    expect_verify_artifact_failure(
        repo,
        missing_file_artifact_dir,
        "error: generated file missing: flake.nix",
    )?;
    Ok(())
}

fn run_artifact_policy_rejection_case(repo: &Path) -> Result<(), String> {
    let artifact_dir = "generated/floating-policy-artifact";
    eprintln!("case: artifact floating input policy rejection");
    run(
        repo,
        "lake",
        &["exe", "leanix", "emit-artifact", "--out", artifact_dir],
    )?;

    let manifest_path = repo.join(artifact_dir).join("leanix.manifest.json");
    let manifest = fs::read_to_string(&manifest_path)
        .map_err(|err| format!("failed reading {}: {err}", manifest_path.display()))?;
    let manifest = manifest
        .replace(
            "\"trustClass\": \"pinned-flake-input\"",
            "\"trustClass\": \"floating-flake-input\"",
        )
        .replace(
            "\"pinPolicy\": \"pinned-ref\"",
            "\"pinPolicy\": \"development-floating-ref\"",
        );
    fs::write(&manifest_path, manifest)
        .map_err(|err| format!("failed writing {}: {err}", manifest_path.display()))?;

    expect_verify_artifact_failure(
        repo,
        artifact_dir,
        "error: artifact input policy rejected: floating flake inputs require a pinned ref or lockfile witness",
    )
}

fn lockfile_witness_manifest(manifest: &str) -> String {
    manifest
        .replace(
            "\"trustClass\": \"pinned-flake-input\"",
            "\"trustClass\": \"lockfile-backed-flake-input\"",
        )
        .replace("\"pinPolicy\": \"pinned-ref\"", "\"pinPolicy\": \"lockfile-witness\"")
        .replace(
            "      \"rev\": \"549bd84d6279f9852cae6225e372cc67fb91a4c1\",\n      \"narHash\": \"sha256-hGdgeU2Nk87RAuZyYjyDjFL6LK7dAZN5RE9+hrDTkDU=\"",
            "      \"lockfile\": \"flake.lock\",\n      \"lockfileNode\": \"nixpkgs\",\n      \"lockedRev\": \"549bd84d6279f9852cae6225e372cc67fb91a4c1\",\n      \"lockedNarHash\": \"sha256-hGdgeU2Nk87RAuZyYjyDjFL6LK7dAZN5RE9+hrDTkDU=\"",
        )
}

fn run_artifact_lockfile_witness_case(repo: &Path) -> Result<(), String> {
    let artifact_dir = "generated/lockfile-witness-artifact";
    eprintln!("case: artifact lockfile witness acceptance");
    run(
        repo,
        "lake",
        &["exe", "leanix", "emit-artifact", "--out", artifact_dir],
    )?;

    let manifest_path = repo.join(artifact_dir).join("leanix.manifest.json");
    let manifest = fs::read_to_string(&manifest_path)
        .map_err(|err| format!("failed reading {}: {err}", manifest_path.display()))?;
    fs::write(&manifest_path, lockfile_witness_manifest(&manifest))
        .map_err(|err| format!("failed writing {}: {err}", manifest_path.display()))?;
    run(
        repo,
        "lake",
        &["exe", "leanix", "verify-artifact", artifact_dir],
    )?;

    let missing_witness_artifact_dir = "generated/missing-lockfile-witness-artifact";
    eprintln!("case: artifact missing lockfile witness rejection");
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "emit-artifact",
            "--out",
            missing_witness_artifact_dir,
        ],
    )?;
    let missing_manifest_path = repo
        .join(missing_witness_artifact_dir)
        .join("leanix.manifest.json");
    let missing_manifest = fs::read_to_string(&missing_manifest_path)
        .map_err(|err| format!("failed reading {}: {err}", missing_manifest_path.display()))?;
    let missing_manifest = missing_manifest
        .replace(
            "\"trustClass\": \"pinned-flake-input\"",
            "\"trustClass\": \"lockfile-backed-flake-input\"",
        )
        .replace(
            "\"pinPolicy\": \"pinned-ref\"",
            "\"pinPolicy\": \"lockfile-witness\"",
        );
    fs::write(&missing_manifest_path, missing_manifest)
        .map_err(|err| format!("failed writing {}: {err}", missing_manifest_path.display()))?;
    expect_verify_artifact_failure(
        repo,
        missing_witness_artifact_dir,
        "error: artifact input policy rejected: lockfile-backed flake inputs require lockfile witness metadata",
    )
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

fn read_generated_output_file(
    repo: &Path,
    out_link: &str,
    relative_file: &str,
) -> Result<String, String> {
    fs::read_to_string(repo.join(out_link).join(relative_file))
        .map_err(|err| format!("failed reading {out_link}/{relative_file}: {err}"))
}

fn run_build_plan_text_file_case(repo: &Path) -> Result<(), String> {
    let output = "generated/flake.nix";
    let out_link = "generated/planned-text-file-result";
    eprintln!("case: build plan text file");
    run(
        repo,
        "lake",
        &[
            "exe",
            "leanix",
            "render-build-plan-text-file",
            "--out",
            output,
        ],
    )?;
    compare_file(repo, output, "e2e/golden/build-plan-text-file.flake.nix")?;
    run(repo, "nix", &["flake", "check", "path:./generated"])?;
    run(
        repo,
        "nix",
        &[
            "build",
            "path:./generated#plannedTextFile",
            "--out-link",
            out_link,
        ],
    )?;
    let message = read_generated_output_file(repo, out_link, "message.txt")?;
    if message == "hello from BuildPlan text file\n" {
        Ok(())
    } else {
        Err(format!("planned text file content mismatch: {message:?}"))
    }
}

fn run_hashed_source_case(repo: &Path) -> Result<(), String> {
    let output = "generated/flake.nix";
    let out_link = "generated/source-fixture-result";
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
    run(
        repo,
        "nix",
        &[
            "build",
            "path:./generated#sourceFixture",
            "--out-link",
            out_link,
        ],
    )?;
    let message = read_generated_output_file(repo, out_link, "message.txt")?;
    if message == "leanix source fixture\n" {
        Ok(())
    } else {
        Err(format!("source fixture content mismatch: {message:?}"))
    }
}

fn require_json_fragment(json: &str, context: &str, fragment: &str) -> Result<(), String> {
    if json.contains(fragment) {
        Ok(())
    } else {
        Err(format!(
            "parsed Nix summary for {context} missing {fragment}"
        ))
    }
}

fn json_static_assign_fragment(name: &str) -> String {
    format!("\"kind\":\"staticAssign\",\"name\":\"{}\"", name)
}

fn require_static_assign(json: &str, context: &str, name: &str) -> Result<(), String> {
    require_json_fragment(json, context, &json_static_assign_fragment(name))
}

fn require_select_path(json: &str, context: &str, path: &[&str]) -> Result<(), String> {
    let mut start = 0usize;
    for name in path {
        let fragment = format!("\"kind\":\"static\",\"name\":\"{}\"", name);
        let offset = json[start..].find(&fragment).ok_or_else(|| {
            format!(
                "parsed Nix summary for {context} missing select path {:?}",
                path
            )
        })?;
        start += offset + fragment.len();
    }
    Ok(())
}

fn check_parsed_output_contract(
    case_name: &str,
    json: &str,
    contract: ParsedOutputContract,
) -> Result<(), String> {
    if !contract.packages.is_empty() {
        require_static_assign(json, case_name, "packages")?;
    }
    if !contract.apps.is_empty() {
        require_static_assign(json, case_name, "apps")?;
    }
    if !contract.dev_shells.is_empty() {
        require_static_assign(json, case_name, "devShells")?;
    }
    if !contract.checks.is_empty() {
        require_static_assign(json, case_name, "checks")?;
    }
    for system in contract.systems {
        require_static_assign(json, case_name, system)?;
    }
    for package in contract.packages {
        require_static_assign(json, case_name, package)?;
    }
    for app in contract.apps {
        require_static_assign(json, case_name, app)?;
    }
    for shell in contract.dev_shells {
        require_static_assign(json, case_name, shell)?;
    }
    for check in contract.checks {
        require_static_assign(json, case_name, check)?;
    }
    for package in contract.default_package_targets {
        require_select_path(json, case_name, &["packages", package])?;
    }

    Ok(())
}

fn check_parsed_contract_rejects_missing_fact(case_name: &str, json: &str) -> Result<(), String> {
    let impossible = ParsedOutputContract {
        systems: &["x86_64-linux"],
        packages: &["leanixMissingPackageForNegativeCheck"],
        apps: &[],
        dev_shells: &[],
        checks: &[],
        default_package_targets: &[],
    };

    match check_parsed_output_contract(case_name, json, impossible) {
        Ok(()) => Err(format!(
            "parsed Nix summary contract for {case_name} accepted a missing package"
        )),
        Err(_) => Ok(()),
    }
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
    let parsed_json = run_capture(
        nixparserlean_dir,
        "nix",
        &[
            "develop",
            "--command",
            "lake",
            "exe",
            "nixparserlean",
            "--desugar",
            "--format",
            "json",
            "--file",
            &output_arg,
        ],
    )?;

    if let Some(contract) = case.parsed_contract {
        eprintln!("interop parsed contract: {}", case.name);
        check_parsed_output_contract(case.name, &parsed_json, contract)?;
        if case.name == "hello" {
            check_parsed_contract_rejects_missing_fact(case.name, &parsed_json)?;
        }
    }

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
            parsed_contract: Some(ParsedOutputContract {
                systems: &["x86_64-linux"],
                packages: &["hello"],
                apps: &["hello", "default"],
                dev_shells: &["default"],
                checks: &["hello"],
                default_package_targets: &["hello"],
            }),
        },
        InteropCase {
            name: "closure",
            render_arg: "render-closure",
            source_arg: false,
            parsed_contract: None,
        },
        InteropCase {
            name: "cli-schema",
            render_arg: "render-cli-schema",
            source_arg: false,
            parsed_contract: Some(ParsedOutputContract {
                systems: &["x86_64-linux"],
                packages: &["hello"],
                apps: &["default"],
                dev_shells: &["default"],
                checks: &["default"],
                default_package_targets: &["hello"],
            }),
        },
        InteropCase {
            name: "showcase",
            render_arg: "render-showcase",
            source_arg: false,
            parsed_contract: Some(ParsedOutputContract {
                systems: &["x86_64-linux"],
                packages: &["helloWrapper", "helloTool"],
                apps: &["default"],
                dev_shells: &["default"],
                checks: &["default"],
                default_package_targets: &["helloWrapper"],
            }),
        },
        InteropCase {
            name: "multi-system",
            render_arg: "render-multi-system",
            source_arg: false,
            parsed_contract: Some(ParsedOutputContract {
                systems: &["x86_64-linux", "aarch64-linux"],
                packages: &["hello"],
                apps: &[],
                dev_shells: &[],
                checks: &[],
                default_package_targets: &["hello"],
            }),
        },
        InteropCase {
            name: "self",
            render_arg: "render-self",
            source_arg: true,
            parsed_contract: None,
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
            name: "library schema flake",
            render_arg: "render-library-schema",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/library-schema.flake.nix"),
        },
        Case {
            name: "formatter schema flake",
            render_arg: "render-formatter-schema",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/formatter-schema.flake.nix"),
        },
        Case {
            name: "multi-app schema flake",
            render_arg: "render-multi-app-schema",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/multi-app-schema.flake.nix"),
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
            name: "multi-system schema flake",
            render_arg: "render-multi-system-schema",
            source_arg: false,
            lean_source: None,
            golden: Some("e2e/golden/multi-system-schema.flake.nix"),
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
            name: "typed check missing package reference",
            render_arg: "render-invalid-typed-check-ref",
            expected_stderr:
                "error: check command typedCheckMissingRef for x86_64-linux refers to missing package missingCheckPackage",
        },
        InvalidCase {
            name: "build plan missing package reference",
            render_arg: "render-invalid-build-plan-ref",
            expected_stderr:
                "error: build plan plannedBroken for x86_64-linux refers to missing package missingPlanDep",
        },
        InvalidCase {
            name: "build plan missing input reference",
            render_arg: "render-invalid-build-plan-input-ref",
            expected_stderr: "error: build expression refers to missing input missingFixtureSrc",
        },
        InvalidCase {
            name: "duplicate build plan arguments",
            render_arg: "render-invalid-build-plan-args",
            expected_stderr:
                "error: duplicate build plan arguments for build plan duplicateBuildPlanArgs",
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
            name: "invalid library schema",
            render_arg: "render-invalid-library-schema",
            expected_stderr: "error: LibraryProject devShell output must be named default",
        },
        InvalidCase {
            name: "invalid formatter schema",
            render_arg: "render-invalid-formatter-schema",
            expected_stderr:
                "error: FormatterProject formatter must point at an existing package missingFormatter",
        },
        InvalidCase {
            name: "invalid multi-app schema",
            render_arg: "render-invalid-multi-app-schema",
            expected_stderr: "error: MultiAppProject must include at least 2 apps",
        },
        InvalidCase {
            name: "invalid multi-system schema",
            render_arg: "render-invalid-multi-system-schema",
            expected_stderr:
                "error: MultiSystemCliProject aarch64-linux invalid: CliProject app must point at the project package",
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
    run_artifact_policy_rejection_case(&repo)?;
    run_artifact_lockfile_witness_case(&repo)?;
    run_source_injection_case(&repo)?;
    run_build_plan_text_file_case(&repo)?;
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
