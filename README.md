# PTMCMCExample

A sample repository to capture example code for the [jellis/PTMCMCSampler][1] library.

This repo contains a Docker image for repeatable execution of PTMCMCSampler in a controlled
runtime environment.  It also repackages PTMCMCSampler's ["simple" Jupyter Notebook][2]
as a Python script to demonstrate execution of that example running an arbitrary number of chains.

## Install instructions

### Clone the repo

```bash
git clone https://github.com/chimaerase/PTMCMCExample.git
```

### Install Docker

[Docker][3] is the de facto standard to build and share containerized apps. Containers are a
standardized unit of software that allows developers to isolate their app from its environment,
resolving the “but it works on my machine” headache.

To use the Docker image, you'll first need to install Docker and Docker-Compose. For most
Mac users, the preferred way of doing this is by downloading and installing [Docker Desktop][4].
You'll need administrative access to your computer to perform the install.

Subsequent instructions assume that Docker is installed and running on your system. You can
test whether Docker is running by executing `docker ps` from the terminal. If Docker is running,
you should get output similar to the following, which shows Docker is up, but no containers
are running.

```bash
>> docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

### Build the Docker image

Build the Docker image locally to create a controlled execution environment for the included 
example code. Builds take approximately 2 minutes on a 2019 MacBook Pro. From your repo base 
directory, run this command to build the Docker image:

```bash
DOCKER_BUILDKIT=1; \
    docker build \
    --pull \
    --no-cache \
    -t ptmcmc-example .
```

This command builds the Docker image from the repo code and tags it with the name `ptmcmc-example`, 
used to reference it in subsequent commands.

## Test the built environment

Before running the PTMCMCSampler code, first run some tests packaged with its dependency `mpi4py`
to help rule out problems in the environment.

Start a Docker container for running the tests.  The `ptmcmc-example` tag used 
during the Docker image build is used to reference it here when using the image to run a container.
This command runs a `bash` shell inside the Debian-based Docker container.  Press CRTL-D to exit 
back to the command prompt for the host OS.

```bash
docker run -it --rm --cap-add=SYS_PTRACE ptmcmc-example
```


Next, from the container's bash prompt, run some examples shipped with `mpi4py`:
```bash
$ mpirun -n 5 python -m mpi4py.bench helloworld
Hello, World! I am process 0 of 5 on 12cbf9dbaed5.
Hello, World! I am process 2 of 5 on 12cbf9dbaed5.
Hello, World! I am process 1 of 5 on 12cbf9dbaed5.
Hello, World! I am process 3 of 5 on 12cbf9dbaed5.
Hello, World! I am process 4 of 5 on 12cbf9dbaed5.
 
# pass a message around a ring of MPI processes for 10 loops
$ mpirun -n 6 python -m mpi4py.bench ringtest --loop 10
time for 10 loops = 0.0007474 seconds (6 processes, 1 bytes)
```

## Run the PTMCMCSampler example

As above, launch (or use) a `bash` shell in a Docker container.  Press CRTL-D to exit the 
container and return to the command prompt for the host OS.

```bash
docker run -it --rm --cap-add=SYS_PTRACE ptmcmc-example
```

For subsequent examples in this section, both example code and PTMCMCSampler code are run from the 
Docker image, so from their state captured at the time of the last Docker image build.  See below 
for other testing options.

Press CTRL-D at any time to exit the container's shell and return to the prompt in the host 
Operating System.

Next, from within the container, run the example code (1 chain first):

```bash
mpiuser@87568b7930cf:/code$ python gaussian_example.py /code/output
Running chain 1 of 1
Chain 1: Starting sampler.sample()
Adding DE jump with weight 20
Finished 99.00 percent in 36.519649 s Acceptance rate = 0.310657
Run Complete
Chain 1 of 1: done in 36.92 s
```

Note that outputs are descriptive and imply success.

Next, re-run the example code within the container, but using `mpirun` to run two chains as 
suggested in the PTMCMCSampler documentation. Node the cryptic read error messages at the end of 
many lines out output.

```bash
$ mpirun -n 2 python /code/gaussian_example.py /code/output
Running chain 2 of 2
Running chain 1 of 2
Chain 2: Starting sampler.sample()
Chain 1: Starting sampler.sample()
[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
Adding DE jump with weight 20
Finished 1.00 percent in 0.386084 s Acceptance rate = 0.387[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
Finished 2.00 percent in 0.806926 s Acceptance rate = 0.324[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
Finished 3.00 percent in 1.230904 s Acceptance rate = 0.304667[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
Finished 4.00 percent in 1.646351 s Acceptance rate = 0.3095[3aab602af2ce:00038] Read -1, expected 80138, errno = 1
... (many more similar errors) ...
Run Complete
Chain 1 of 2: done in 45.23 s
Chain 2 of 2: done in 45.23 s
```

List output files: note that one resulting `chain_*` file (`chain_1.316227766016838.txt` in this 
example) is empty.

```bash
$ ls -l output/
total 52140
-rw-r--r-- 1 mpiuser mpiuser      198 Oct  4 23:23 DEJump_jump.txt
-rw-r--r-- 1 mpiuser mpiuser 53359822 Oct  4 23:23 chain_1.0.txt
-rw-r--r-- 1 mpiuser mpiuser        0 Oct  4 23:23 chain_1.316227766016838.txt
-rw-r--r-- 1 mpiuser mpiuser     3328 Oct  4 23:23 cov.npy
-rw-r--r-- 1 mpiuser mpiuser     1098 Oct  4 23:23 covarianceJumpProposalAM_jump.txt
-rw-r--r-- 1 mpiuser mpiuser     1103 Oct  4 23:23 covarianceJumpProposalSCAM_jump.txt
-rw-r--r-- 1 mpiuser mpiuser     1121 Oct  4 23:23 jump_jump.txt
-rw-r--r-- 1 mpiuser mpiuser       85 Oct  4 23:23 jumps.txt
```

### Testing code changes

To test code changes, you can temporarily mount files or directories on your host computer as 
volumes in a Docker container.  They'll override any pre-existing files in the container.  So 
for example:

   * To make outputs from within the container available from your host OS, use the `-v` option
     for `docker run` to mount a directory on your host OS to a directory under `/code` in the
     Docker container.
   * To test changes to `gaussian_example.py`, run the Docker container as follows:
     `docker run -it --rm -v /path/to/your/repo/gaussian_example.py:/code/gausssian_example.py ptmcmc-example`
   * To test changes to PTMCMCSampler, launch a Docker container and make temporary changes to 
     allow testing.  Changes to the container only persist as until you exit it.  Persistent 
     changes should be made to the Dockerfile or its dependencies (e.g. `Pipfile*` files.):

``` bash
# Launch a Docker container as above, but as the container's root user so we can make changes to 
# the system Python packages.  The `-v` option also mounts your PTMCMCSampler code from your local 
# filesystem to the container under  `/code/`.
docker run -it --rm -v /path/to/your/PTMCMCSampler-repo/PTMCMCSampler:/code/PTMCMCSampler --user root ptmcmc-example

# remove the released PTMCMCSampler code while leaving all other supporting packages unchanged.  
# This change will persist only until you stop the container.
pip uninstall ptmcmcsampler

# change ownership of the mounted PTMCMCSampler code to the `mpiuser`
chown -R mpiuser:mpiuser /code/PTMCMCSampler

# change to the `mpiuser` user to allow executing `mpirun` without errors for testing
# (root is not allowed). CTRL-D do exit back to the container's root account.
su mpiuser
 ```

You can also combine the two testing approaches above to simultaneously iterate on both the example
code and PTMCMCSampler code.

---

[1]: https://github.com/jellis18/PTMCMCSampler
[2]: https://github.com/jellis18/PTMCMCSampler/blob/master/examples/simple.ipynb
[3]: https://www.docker.com/
[4]: https://www.docker.com/products/docker-desktop