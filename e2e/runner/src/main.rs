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

    run(repo, "nix", &["flake", "check", "path:./generated"])?;
    if let Some(golden) = case.golden {
        let generated = fs::read_to_string(repo.join(output))
            .map_err(|err| format!("failed reading generated output: {err}"))?;
        let expected = fs::read_to_string(repo.join(golden))
            .map_err(|err| format!("failed reading golden output {golden}: {err}"))?;
        if generated != expected {
            return Err(format!("generated output differs from {golden}"));
        }
    }

    Ok(())
}

fn run_invalid_case(repo: &Path, case: &InvalidCase) -> Result<(), String> {
    let output = "generated/invalid-flake.nix";
    eprintln!("case: {}", case.name);

    let status = Command::new("lake")
        .args(["exe", "leanix", case.render_arg, "--out", output])
        .current_dir(repo)
        .stdin(Stdio::null())
        .status()
        .map_err(|err| format!("failed to start lake: {err}"))?;

    if status.success() {
        Err(format!(
            "invalid case '{}' unexpectedly rendered successfully",
            case.name
        ))
    } else {
        Ok(())
    }
}

fn repo_root() -> Result<PathBuf, String> {
    env::current_dir().map_err(|err| format!("failed to read current directory: {err}"))
}

fn main() -> Result<(), String> {
    let repo = repo_root()?;
    let cases = [
        Case {
            name: "typed hello flake",
            render_arg: "render-example",
            source_arg: false,
            lean_source: None,
            golden: None,
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
            golden: None,
        },
        Case {
            name: "typed CLI schema flake",
            render_arg: "render-cli-schema",
            source_arg: false,
            lean_source: None,
            golden: None,
        },
        Case {
            name: "proof-carrying CLI closure showcase",
            render_arg: "render-showcase",
            source_arg: false,
            lean_source: Some("examples/proof-carrying-cli-closure/source.lean"),
            golden: Some("examples/proof-carrying-cli-closure/expected.flake.nix"),
        },
    ];
    let invalid_cases = [
        InvalidCase {
            name: "missing package reference",
            render_arg: "render-invalid-missing-ref",
        },
        InvalidCase {
            name: "package dependency cycle",
            render_arg: "render-invalid-cycle",
        },
        InvalidCase {
            name: "invalid CLI schema",
            render_arg: "render-invalid-cli-schema",
        },
    ];

    for case in cases {
        eprintln!("case: {}", case.name);
        run_case(&repo, &case)?;
    }

    for case in invalid_cases {
        run_invalid_case(&repo, &case)?;
    }

    eprintln!("e2e: all cases passed");
    Ok(())
}
