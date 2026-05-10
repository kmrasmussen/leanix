use std::env;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

struct Case {
    name: &'static str,
    render_arg: &'static str,
    source_arg: bool,
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
        },
        Case {
            name: "self flake",
            render_arg: "render-self",
            source_arg: true,
        },
        Case {
            name: "typed closure flake",
            render_arg: "render-closure",
            source_arg: false,
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
