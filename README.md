# PRS-hub_offline

PRS-hub is a platform for batch offline calculation of various Polygenic Risk Score (PRS) methods, built on WDL, allowing for local or server-based execution. Below are detailed instructions for installation, dependencies, and usage.

## Installation

1. Clone this repository:

    ```bash
    git clone https://github.com/yourusername/PRS-hub.git
    ```

2. Set the `PRSHUB_PATH` environment variable in your `.bashrc` file to quickly call scripts from the installation path:

    ```bash
    export PRSHUB_PATH=`pwd`/PRS-hub_offline
    ```

3. Save and source the `.bashrc` file to apply changes:

    ```bash
    source ~/.bashrc
    ```

If the installation path changes, simply update the `PRSHUB_PATH` value accordingly.

## Dependencies

To ensure the platform runs correctly, please install the following software and dependencies:

1. **Cromwell**: This platform is based on WDL (Workflow Description Language), so Cromwell is required to execute WDL scripts. You can download Cromwell and refer to the installation instructions on the [Cromwell GitHub page](https://github.com/broadinstitute/cromwell).

2. **R and Python**:
   - **R** and **Python** need to be included in the `PATH` to allow direct usage of the `Rscript` and `python` commands. If not installed, they can be added via Conda, and the Conda environment path can be appended to `.bashrc`.

     For example, install R and Python using Conda:

     ```bash
     conda install -c conda-forge r-base python
     ```

3. **R Packages**: Install the following R packages to ensure compatibility with the environment.
   - Use the following command to install the required R packages:

     ```R
     install.packages(c("pacman", "dplyr", "docopt", "rio", "data.table", "magrittr", "bigsnpr"))
     ```

4. **Python Packages**:
   - **scipy**: Required for scientific computing. For details, refer to the [Scipy official website](https://www.scipy.org/).
   - **h5py**: Needed for handling HDF5 file formats. For details, refer to the [H5py official website](https://www.h5py.org/).

   Install the Python packages with:

   ```bash
   pip install scipy h5py
   ```
   
## Usage

1. To execute a specific algorithm WDL file using Cromwell, use the following command, replacing `<algorithm_name>` with the name of the desired algorithm:

    ```bash
    java -jar /path/to/cromwell.jar run $PRSHUB_PATH/wdl/<algorithmname>.wdl --inputs /path/to/config_file
    ```

   - `/path/to/cromwell.jar` is the path to the Cromwell JAR file.
   - `$PRSHUB_PATH/wdl/<algorithm_name>.wdl` is the path to the WDL file for the chosen algorithm.
   - `--inputs /path/to/config_file` specifies the path to the configuration file, which contains the parameter settings for the algorithm.

2. Each algorithm's supported configuration file parameters can be found in the `config_example` folder. Adjust the parameters in the configuration file according to the requirements of each algorithm.

Thank you for using PRS-hub!
