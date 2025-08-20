# 2025-08-13 10:12 - first snakemake tutorial

This project is to create a snakemake worflow that is then deployed using GitHub Actions.

The available hardware specs for Linux virtual machines are:
- 2 core CPUs
- 7 GB RAM
- 14 GB of SSD space

Therefore some parts of the pipeline can be used for other use cases, as long as you then remove the constraints.
The projects starts by addressing the space constraints (2-9), then RAM constraints (10), and then the cores.

TO REMEMBER:
1. When writing a qmd/R script that should go into a Snakemake pipeline:
- convert from qmd to R
- add a shebang line to the top of the file
- change the paths such that they are seen relative to the directory where the Snakefile is located.
- delete the parts you don't necessarily need

2. How to run a snakemake pipeline:
- by rule name
```bash
snakemake --dry-run --cores 1 --use-conda --conda-prefix env_tar/smk get_all_archive
```

- by output
```bash
snakemake --dry-run results/5_world_drought.png
```
---

## 0. Git
- https://github.com/FerallOut/lrn_1_Riffomonas_project

## 1. Create project structure
```bash
mkdir -p 1_smk/
1_snakemake_intro_youtube_CC248/{annotations,data,docs,envs,env_tar,results,scripts}
cd 1_smk/1_snakemake_intro_youtube_CC248
```

Download annotations from the readme file separately
```bash
wget -nc https://www.ncei.noaa.gov/pub/data/ghcn/daily/readme.txt -P annotations/
```

## 2. Create and activate a new conda environment with mamba
```bash
vim envs/smk_env1.yaml

## either of:
mamba env create --name smk_env1 --file envs/smk_env1.yaml

mamba env create -p env_tar/smk_env1 --file envs/smk_env1.yaml

conda activate env_tar/smk_env1

## as you go installing packages,
## add the version to the yaml file
## to look at a specific package version:
conda list | grep "snakemake"
```

## 3. find the locations of the files you want to download 
- https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/
- right-click on the file you want to download to copy the link address

## 4. write each script and make them executable

### 4.A. create the download scripts
- scripts/1_get_ghcnd_all.sh
- scripts/2_get_ghcnd_all_stations.sh
- scripts/3_get_ghcnd_inventory.sh

- make the scripts executable

```bash
chmod +x scripts/get_ghcnd_data.sh
```

- OBS: if you want to run the scripts manually, you can run them like this:
```bash
 ## started in the background and run sequentially:
{ sleep 2; sleep 3; } &

## run the second only if first succeeds:
sleep 2 && sleep 3 &

## run in parallel in the background:
sleep 2 & sleep 3 &

## And the two techniques could be combined:

{ sleep 2; echo first finished; } & { sleep 3; echo second finished; } &
```

### 4.B. reuse one script for all downloads 
Since for the previous 3 scripts the only difference was the name of the script to download but the path was always the same, we can use the same script to download all the files
- scripts/4_get_ghcnd_data.sh

To run it, after making it executable:
```bash
scripts/4_get_ghcnd_data.sh ghcnd_all.tar.gz
scripts/4_get_ghcnd_data.sh ghcnd-inventory.txt
scripts/4_get_ghcnd_data.sh ghcnd-stations.txt
```

But, to automate it further, create a driver script that will run all the previous scripts in order:
- scripts/5_driver.sh

Obs: because of how the driver script is written, it can only be run from the parent directory of the "scripts" directory

You can now remove scripts 1-3 because they are no longer needed.

## 5. List all files in the archive
- scripts/6_get_ghcnd_all_files.sh

Add the code to the driver script (scripts/5_driver.sh) 



## 6. Create the Snakefile
- Snakefile

This file will replace "scripts/5_driver.sh", and at the end it can be deleted  

### 6.A. Write each rule and verify it works

```bash
## activating the conda env is optional
## if you don't, then just mention it on the command line below
conda activate env_tar/smk_env1

## dry run to test the "get_all_archive" rule
## either
snakemake --dry-run --cores 1 --use-conda --conda-prefix env_tar/smk get_all_archive
snakemake -np --cores 1 --use-conda --conda-prefix env_tar/smk_env1 get_all_archive
```

### 6.B. Run all the rules in the Snakefile

If you don't mention the name of the rule, it runs only the first one. To run all the rules, you need to create a "target" or "all" rule, and add it as the first rule in the Snakefile.

The input for the "all" rule are the outputs of the other rules, so it will run all the rules in order.

Now run snakemake again.

```bash
snakemake --cores 1 --use-conda --conda-prefix env_tar/smk_env1
```

## 7. Visualize the DAG
You can visualize the DAG of any rule, including the "targets/all" rule. Need "graphviz" installed in the conda environment. It doesn't run the rules.

```bash
#snakemake --dag <target_rule> | dot -Tsvg > dag_<rule_name>.svg

snakemake --dag all --cores 1 --use-conda --conda-prefix env_tar/smk_env1 | dot -Tpng > results/dag_all.png

snakemake --dag get_all_file_names --cores 1 --use-conda --conda-prefix env_tar/smk_env1 | dot -Tpng > results/dag_get_all_file_names.png
```

## 8. Clean up
You can delete the scripts 1-3 and 5 and only run the Snakefile to get all the data you need.

## 9. Add R scripts to Snakemake

### 9.A. create a script to process a small nr of files
- scripts/7_read_dly_files.qmd - 1st and 2nd portion of the script

The goal is to learn how to read in only first 3 files from the archive we have downloaded and then to expand this analysis to all files

```bash
## extract to "data" dir only these 3 files
tar -xvzf data/ghcnd_all.tar.gz -C data/ ghcnd_all/ASN00017066.dly ghcnd_all/ASN00040510.dly ghcnd_all/ASN00008255.dly
```
Process the data from those 3 files 

### 9.B. work with one file at a time
This is necessary if you are under space constraints, such as when you are relying on github Actions to download and then extract data. 
For GitHub Actions the space is limited to 14 GB (?), so expanding a large archive is out of the question.
- scripts/7_read_dly_files_all.qmd - 3rd portion of the script

Also, running through more than 100.000 files will take a very long time in this way. GitHub Actions allows you to use up to 3 processors. Still this would take too long.

So, use this file if you don't have space/CPU constraints, otherwise use the next script.


## 10. ways to deal with memory issues
When checking "htop", this script used more than 22.7 GB. Since GitHub Actions allows only 14GB, we need a work around

Ways to go around this block:
- reduce size of the input file
- chunk parts of the analysis - instead of doing conversions on all 100.000 files, do it on e.g. 100 at a time
- remove up front useless data - a lot of the data in these files is zero, and it is not needed, it can be removed to facilitate computation

### 10.A. read in the archive, filter and rezip 

In bash you can use "split" to chunk the input archive that has 100.000 files and can choose to filter the files in the process, further reducing the overall size of the input.

Try to create one concatenated file with all the necessary data.

```bash
## x - extract 
## v - verbose
## z - compress to gzip
## f - file name = location of file

## extract a particular file from the archive to another location
tar -xvzf ../data/ghcnd_all.tar.gz ghcnd_all/ASN00017066.dly

## c - create a new archive

## create a new archive from all the files in the ghcnd_all directory
tar -cvzf ../data/practice.tar.gz ../data/ghcnd_all/

## t - list contents of archive

## list contents of archive
tar -tvf ../data/practice.tar.gz

## O - output to stdout, not to disk
tar -Oxvzf ../data/practice.tar.gz > practice.out
```

Work on zipping and concatenation

```bash
## k - keep the original file after compression
gzip -k ../data/practice.out 

## unzip the archive
gunzip ../data/practice.out.tar.gz

## important: you can filter on the information within each file of the archive
## when using output to stdout
tar -Oxvzf ../data/practice.tar.gz | grep "PRCR" | gzip > ../data/practice2.out.gz
```
Add new file as a rule to Snakefile
- scripts/8_split_ghcnd_all.sh

Modify the code to read the concatenated file
- scripts/7_read_dly_files_all.qmd - 4th portion of the script


### 10.B. chunk input data using "split" function


```bash
split --help
## most commonly used: --bytes, --lines, --number

## split the archive into 40 chunks -> one chunk unzipped ~ 0.75 GB; zipped ~ 84 MB
## all file names start with "x"
split -n 40 ../data/ghcnd_all.tar.gz
ll x*
wc -l x*

## split the archive into chunks of 40 * 10^6 bytes -> 88 files of 39 MB each
split -b 40000000 ../data/ghcnd_all.tar.gz

## if you have an unzipped file, you can split it by nr of lines
## split into 123 files of 1000 lines each
split -l 1000 ../data/ghcnd_all/ghcnd_all.txt
ls x* | wc -l
```

Modify scripts/8_concatenate_dly.sh
Convert script 7 to scripts/9_read_split_dly_files_all.qmd to see if it works on a chunked file. Remove the useless PRCP filters and element removal column.

When running script 9, we observe that some of the rows in the new dataframe have 0 in the 'prcp' column (= no precipitation). Since we need only that info, we can remove those rows directly to reduce size even further.

| | | |
|---|---|---|
|ASN00027001|1913-12-01|0|
|ASN00027001|1913-12-02|0|
|ASN00027001|1913-12-03|0|

Remove the rows with 0 in the 'prcp' column.

Add new file as a rule to Snakefile
- scripts/8_split_ghcnd_all.sh


At the end, one of the 36 split files has ~ 5 mil rows -> ~ 209 mil rows in total after concatenation.

### 10.C remove useless data
In this case, remove data that is outside your area of interest, in this case outside your time window.

- scripts/9_read_split_dly_files_all.qmd

Transform the date into Julian date (meaning each day is given a number between 1 and 365/ 366) 
to make it easier to establish time windows and filters. 

Add indicator column if date in window, add "year" column to be able to 
fix the year indication by adding 1 if date is in window but different year.

The size of the output file is quite small. 
To test if this is enough for GitHub Actions 
(i.e. small enough to run all split files through with piece of code from script 9),
convert the code into function and apply it to all split files.

Important: For the Snakemake pipeline to run an R script, you need to add the shebang line at the top and make it /executable

HOW TO RUN A QUARTO FROM SNAKEMAKE?

Convert from Quarto to R and make it executable

```bash
Rscript -e "library(knitr); knitr::purl('9_read_split_dly_files_all.qmd', documentation =2)"
chmod +x 9_read_split_dly_files_all.qmd
```
- script/9_read_split_dly_files_all.R

Add info to 8_concatenate_dly.sh (last addition)

Modify the Snakefile; delete the rule "concatenate_dly_files" and replace it with "summarize_dly_files"
```bash
snakemake --dag  | dot -Tpng > results/3_dag_stage_all.png
```

How to force snakemake to rerun a rule:
- could delete the actual file used as output by that rule and rerun snakemake
- or you could:
  - check the dag
  ```bash
  snakemake --dag  | dot -Tpng > results/3_dag_stage_all.png
  ```
  - find the rule you want to update and all the rules depending on it,
  in this case: "get_all_archive" -> "get_all_filenames", "summarize_dly_files" -> "all"

  - force it:
  ```bash
  snakemake -R get_all_archive get_inventory get_station_data -c4
  ```




## 11. cleanup 
Make a copy of only the necessary files and keep them in 'scripts'. All the scripts are put in 'learn_scripts' to be able to follow the tutorial again.

## 12. further data summarization
Since the goal is to create a global map with precipitations on it, we could merge 
the data from weather stations that are close to each other. Either:

- calculate distance between each weather station, 
cluster them and get the average amount of precipitation over the window time in each cluster.

- or get the latitude and longitude of each of the weather stations, round them and then pool the values from the stations that are within the same latitude and longitude.

We will go with option 2:

### 12.A. Rounding in R 
- a floating point number = double - number with decimals
- scripts/10_rounding_in_R.qmd - to see various ways to round numbers in R

- load the "ghcnd-stations.txt" to get coordinates and to figure how to proceed.
The file is another fixed width formatted file, but now load it in a different way than in scripts 7/9.
Round the numbers, group and count. 

### 12.B. Get both precipitation and location
- this info is in the "ghcnd-inventory.txt" - so change script 10 to 11, and only process this data file.
- Make R scripts executable, add shebang line. 
Change the Snakemake file, adding rule "get_regions_years".

```bash
Rscript -e "library(knitr); knitr::purl('11_get_regions_years.qmd', documentation =2)"
chmod +x 11_get_regions_years.qmd
```

### 12.D. join together the data
To get the precipitation for the last month from all weather stations and to plot it:
- scripts/12_merge_weather_stations_data.qmd

Refactor code into "scripts/13_plot_drought_by_region.qmd"
-  when you decide to refactor a script, save outputs and checks to be able to verify if you get the same output.

## 13. Create a webpage on GitHub ///- todel? Start on GitHub Actions
We can use GitHub to host websites for us.
- create "index.html" just with "Hello world!" message. Add it to git.
- in the repo > "Settings" > "Pages" > 
  - "Source" > "Deploy from a branch"
  - "Branch" > "main" > "/(root)" > Save

Now modify the "index.html" to display proper visualization,
meaning just the static image of the output plot
- create "index.Rmd" - I made it into a qmd file: "index_1.qmd"
- then render it to replace the initial "index.html" file.
- to see the output in a browser, do:
```bash
open index.html
```

### 13.A. CSS modifications
At this point, do cosmetic changes to the "index_2.qmd" -> "index.html" files:
- move author name under the image
- make background black to match the image background
- make the image take up the whole width of the page

When writing the "css" code in the "index.qmd", specify the engine you want to use
(e.g. knitr), otherwise it calls for python and jupyter (
https://forum.posit.co/t/why-is-a-quarto-trying-to-run-python-when-i-render-a-document-with-stan-code-chunk/169231/3)

Comment out in css using "/*   */" marks

If you don't know how to point to an attribute (e.g the title, the image, etc), 
right-click on it and then "Inspect element".

Rmd and qmd have different ways to modify the output of the file

1. Quarto modifications

```yaml
# for qmd change the header:

include-in-header:
  - text: |
      <style>
      .quarto-title-meta-heading {
        display: none;
      }
      .quarto-title-meta-contents {
        display: none;
      }
      </style>
```

Then add this just above and below the image, not in a chunk:
::: {.column-screen}
![](results/5_world_drought.png)
:::

To refer to the git hub mentioned in the yaml header:

A.

```{yaml}

# header:
params:
  github_repo: https://github.com/FerallOut/lrn_1_Riffomonas_project
```

Call for it like this:
  
```{r}  
paste0("the param is: ", params[["github_repo"]])

```
or:

Site [developed](`r params[["github_repo"]]`) by [MB]()

B.

```yaml
github_repo: https://github.com/FerallOut/lrn_1_Riffomonas_project
```

call:

Site [developed](`r rmarkdown::metadata$github_repo2`) by [MB]()

2. Rmd modifications

```{css echo = FALSE}
/* for Rmd, add this code a first chunk */

/* prevent display of author name and document title */
.author, .title {
  display: none;
}

/* make plot full width */
.main-container {
  max-width: 100%;
}

/* change color of background to black and 
letters to white */
body {
  background-color: black;
  color: white;
  font-size: 1.2vw;       /* dynamic update of font sizes; em would be constant size */
}
```


Change header:

```yaml
github_repo: https://github.com/FerallOut/lrn_1_Riffomonas_project
```

Call like this:

Site [developed] (`r github_repo`) by [MB]()


C. can also call metadata like this: 
https://stackoverflow.com/questions/74148370/how-to-insert-a-date-string-in-a-paragraph-in-quarto

```yaml
date: "19.Aug.2025"
date-modified: last-modified
date-format: "DD.MMM.YYYY"
```

call:

Last updated on {{< meta date-modified >}}


### 13.B. Snakemake rule for rendering

This is how you can run qmd scripts with Snakemake:

```bash
rule render_index:
    input:
        qmd_script = "index.qmd",
        png = "results/5_world_drought.png"
    output:
        "index.html"
    shell:
        """
        quarto render {input.qmd_script} --to html
        """
```

## 14. Use Github Actions 
So far we have an website with a static image on somewhat old data. We want the image to be updated daily.
https://www.youtube.com/watch?v=t1MGEVeTgQM&list=PLmNrK_nkqBpK6iqwN3QeQyXqI6DrcGgIm&index=14

Mostly work on the Github website.

### 14.A. website exploration
Github has a Github Actions quickstart tutorial:
https://docs.github.com/en/actions/get-started/quickstart

- create ".github/workflows/github-actions-demo.yml" using the website (it should work with CLI as well?)
  - "Add file" > ".github" > "workflows" > "run_pipeline.yml" 
- in the file paste the contents from the quicktutorial YAML content
- commit the file  

- press "Actions" button on top of the page
  - you can see that the website ran and checked the yml script
  - press on "FerallOut is testing out GitHub Actions" > "Explore-GitHub-Actions" to see the different steps that were run

- back to ".github/workflows/run-pipeline.yml" file:
1. what each term means:
  - ${{ github.actor }} - variable that inserts your GitHub name (no need to change)
  - "on: push" - if you make a commit and push on this GitHub repo, the website will automatically run this Action
  - "jobs" - what kind of jobs you want on this repo; current just one: "Explore-GitHub-Actions"
  - "runs-on" - the type of computer you want the Action to run on (= the runner); think of it as an HPC that in this case runs latest Ubuntu
  - "steps" - 
    - "${{ github.event_name }}" - the action, in this case "push"
    - "${{ runner.os }}" - the os, in this case "latest-ubuntu"
    - "${{ github.ref }}" - the branch, in this case "main"
    - "${{ github.repository }}" - repo name
    - "actions/checkout@v3" - a copy of your repo is copied/ checked out to the remote computer you want to use (~ clonning the repo)
    - "${{ github.workspace }}" - lists all files in the repo/ workspace (e.g. Snakemake, index, README, code/, results/, etc)
    - "${{ github.status }}" - outputs the status of the job, if it is successful or not 

 2. modify it to suit your analysis
  - after the " workspace " rule, add:
    A. test by adding a "pwd" command to see what is the working directory
     "- name: Get working directory
          run: |
            pwd" 

    - commit the change, then go back to Actions to see how GitHub checks the changes and runs Actions on your repo
      - "Actions" > click on the one you want, e.g. Demo #2 > "Explore-GitHub-Actions" > check on your new rule e.g. "Get working directory"
    - now replace this rule and add more:

  B. set up the env to have the correct software
    - we have a conda env with all needed tools
    - but for GitHub Actions, first install Snakemake, and then using it, you install conda, because using the Snakemake file, you can create separate environments for each rule
      - go to the quickstart tutorial and copy the "Testing" rule: https://github.com/snakemake/snakemake-github-action
      - paste it into the yml file you created on github (.github/workflows/run_pipeline.yml) and modify it
        - change name at the top from "GitHub Actions Demo" to: "Run Drought Index Workflow"   
        - change name of the job from "Explore-GitHub-Actions:" to "Run-Drought-Index-Workflow:"
        - in the piece of code you pasted, change: 
          - name from "Testing" to "Snakemake-workflow"
          - directory from ".test" to "."
          - snakefile location and name from 'workflow/Snakefile' to "Snakefile"
        - don't change the snakemake name since ours is also called "Snakefile", nor the number of cores since the pipeline was developed with 1 core in mind
    
    - if you save and commit, then GitHub Actions will take some time to fail. It will run the pipeline through data download, and fail when it hits the R scripts that need specific libraries to run.

    - go back to the Snakemake file and add "conda" directives, pointing it to our env yaml.

  C. run the Snakemake workflow

  D. commit any changes that occur because we ran the output (e.g. the final plot output)


### 14.B. 











# Todo:
[ ] at the end, recreate the env.yaml file from the env to preserve the library versions

[x] test script 4, if it needs {} - no, it does not need them
    - https://stackoverflow.com/questions/8748831/when-do-we-need-curly-braces-around-shell-variables
    - https://nickjanetakis.com/blog/why-you-should-put-braces-around-your-variables-when-shell-scripting

[x] test script 5 to see if it works

[x] install "graphviz" in env and add it to the yaml file

[ ] check out "tidylog"


# Ideas skip
- [ ] run R quarto in VSCode terminal
- [ ] error it is taking the path hardcoded - how to just load it from the conda env?
- [x] how to run Quarto script from snakemake
