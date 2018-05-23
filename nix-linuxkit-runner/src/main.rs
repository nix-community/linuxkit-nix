#[macro_use]
extern crate structopt;
extern crate ctrlc;


use std::path::PathBuf;
use structopt::StructOpt;
use std::process::{Command, Stdio};
use std::{thread, time};
use std::fs;
use std::path::Path;

#[derive(StructOpt, Debug)]
#[structopt(name = "nix-linuxkit-runner")]
struct Config {
    /// Enable verbose / debug mode
    #[structopt(short = "v", long = "verbose")]
    verbose: bool,

    /// Absolute path to the hyperkit executable
    #[structopt(long = "hyperkit", parse(from_os_str))]
    hyperkit: PathBuf,

    /// Absolute path to the vpnkit executable
    #[structopt(long = "vpnkit", parse(from_os_str))]
    vpnkit: PathBuf,

    /// Absolute path to the linuxkit executable
    #[structopt(long = "linuxkit", parse(from_os_str))]
    linuxkit: PathBuf,

    /// Root directory for storage of state
    #[structopt(long = "state-root", parse(from_os_str))]
    state_root: PathBuf,

    /// Root directory for the kernel files, expecting a structure like this:
    ///
    /// For the argument --kernel-files=/foo/bar/kernel-files/
    /// it'll look for:
    ///
    ///     /foo/bar/kernel-files/cmdline
    ///     /foo/bar/kernel-files/initrd.img
    ///     /foo/bar/kernel-files/kernel
    ///
    /// For the argument --kernel-files=/foo/bar/kernel-files/foo
    /// it'll look for:
    ///
    ///     /foo/bar/kernel-files/foo-cmdline
    ///     /foo/bar/kernel-files/foo-initrd.img
    ///     /foo/bar/kernel-files/foo-kernel
    #[structopt(long = "kernel-files", parse(from_os_str))]
    kernel_files: PathBuf,

    /// IP address of the system
    #[structopt(long = "ip")]
    ip: String,

    /// Number of cores to allocate to the system
    #[structopt(long = "cpus", default_value = "1")]
    cpus: u8,

    /// Size of the root disk, in gigabytes
    #[structopt(long = "disk-size", default_value = "80")]
    disk_size: u16,

    /// Amount of RAM to allocate to the system, in megabytes
    #[structopt(long = "memory", default_value = "4096")]
    memory: u16,
}

fn main() {
    let options = Config::from_args();

    let mut disk = options.state_root.clone();
    disk.push("nix-disk");

    let mut datafile = options.state_root.clone();
    datafile.push("server-config.tar");

    let mut vm_state = options.state_root.clone();
    vm_state.push("nix-state");

    let mut hyperkit_pid = vm_state.clone();
    hyperkit_pid.push("hyperkit.pid");

    if options.verbose {
        println!("Hyperkit PID at: {:?}", hyperkit_pid);
    }

    let hyperkit = HyperKit::new(hyperkit_pid.to_str().unwrap());

    if hyperkit.is_running() {
        hyperkit.kill_and_wait();
    }
    hyperkit.delete_pidfile().expect("cannot clean up pidfile");

    ctrlc::set_handler(move || {
        println!("Killing hyperkit");
        hyperkit.kill_and_wait();
    }).expect("Error setting Ctrl-C handler");

    let mut child = Command::new(options.linuxkit);
    child.stdin(Stdio::piped());
    child.stdout(Stdio::inherit());
    child.stderr(Stdio::inherit());
    if options.verbose {
        child.arg("-verbose");
    }
    child.args(&["run", "hyperkit"]);
    child.args(&["-hyperkit", options.hyperkit.to_str().unwrap()]);
    child.args(&["-vpnkit", options.vpnkit.to_str().unwrap()]);
    child.args(&["-console-file"]);
    child.args(&["-networking", "vpnkit"]);
    child.args(&["-ip", &options.ip]);
    child.args(&["-disk", &format!("{},size={}G", disk.to_str().unwrap(), options.disk_size)]);
    child.args(&["-data-file", datafile.to_str().unwrap()]);
    child.args(&["-cpus", &format!("{}", options.cpus)]);
    child.args(&["-mem",  &format!("{}", options.memory)]);
    child.args(&["-state", vm_state.to_str().unwrap()]);
    child.arg(options.kernel_files.to_str().unwrap());

    if options.verbose {
        println!("executing: {:?}", child);
    }

    let mut process = child.spawn().expect("Failed to spawn the linuxkit child process!");
    let result = process.wait().expect("can't wait for linuxkit?");
    println!("linuxkit's ending state: {:?}", result);
    println!("Bye!");
}

struct HyperKit {
    pidfile: String,
}

impl HyperKit {
    pub fn new(pidfile: &str) -> HyperKit {
        HyperKit {
            pidfile: pidfile.to_owned()
        }
    }

    pub fn is_running(&self) -> bool {
        Command::new("/usr/bin/pgrep")
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .args(&["-F", &self.pidfile, "hyperkit"])
            .spawn().expect("Failed to spawn pgrep child process!")
            .wait().expect("Can't wait for the pgrep child?")
            .success()
    }

    pub fn kill_and_wait(&self) {
        self.kill();
        while self.is_running() {
            println!("Waiting for hyperkit to die");
            thread::sleep(time::Duration::from_millis(500));
        }
    }

    pub fn kill(&self) -> bool {
        Command::new("/usr/bin/pkill")
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .args(&["-F", &self.pidfile, "hyperkit"])
            .spawn().expect("Failed to spawn pkill child process!")
            .wait().expect("Can't wait for the pkill child?")
            .success()
    }

    pub fn delete_pidfile(&self) -> Result<(),&'static str> {
        if let Err(x) = fs::remove_file(&self.pidfile) {
            println!("Possibly fine error removing the pidfile: {:?}", x);
        }

        if Path::new(&self.pidfile).exists() {
            return Err("Failed to delete hyperkit's pidfile!");
        }
        return Ok(());
    }
}
