rule all:
    input:
        "data/ghcnd_all.tar.gz",
        "data/ghcnd-inventory.txt",
        "data/ghcnd-stations.txt",
        "data/6_ghcnd_all_files.txt",
        "data/9_ghcnd_tidy.tsv.gz",
        "data/11_ghcnd_regions_years.tsv",
        "results/5_world_drought.png"

rule get_all_archive:
    input:
        script = "scripts/4_get_ghcnd_data.sh"
    output:
        archive = "data/ghcnd_all.tar.gz"
    params:
        file = "ghcnd_all.tar.gz"
    shell:
        """
        {input.script} {params.file}
        """

rule get_all_file_names:
    input:
        script = "scripts/6_get_ghcnd_all_files.sh",
        archive = "data/ghcnd_all.tar.gz"
    output:
        file = "data/6_ghcnd_all_files.txt"
    shell:
        """
        {input.script} 
        """

rule get_inventory:
    input:
        script = "scripts/4_get_ghcnd_data.sh"
    output:
        inventory = "data/ghcnd-inventory.txt"
    params:
        file = "ghcnd-inventory.txt"
    shell:
        """
        {input.script} {params.file} 
        """
rule get_station_data:
    input:
        script = "scripts/4_get_ghcnd_data.sh",
    output:
        data = "data/ghcnd-stations.txt"
    params:
        file = "ghcnd-stations.txt"
    shell:
        """
        {input.script} {params.file} 
        """

rule summarize_dly_files:
    input:
        bash_script = "scripts/8_concatenate_dly.sh",
        r_script = "scripts/9_read_split_dly_files_all.R",
        tarball = "data/ghcnd_all.tar.gz"
    output:
        file = "data/9_ghcnd_tidy.tsv.gz"
    shell:
        """
        {input.bash_script}
        """

rule get_regions_years:
    input:
        r_script = "scripts/11_get_regions_years.R",
        file = "data/ghcnd-inventory.txt"
    output:
        file = "data/11_ghcnd_regions_years.tsv"
    shell:
        """
        {input.r_script} 
        """

rule drought_by_region:
    input:
        r_script = "scripts/13_plot_drought_by_region.R",
        prcp_data = "data/9_ghcnd_tidy.tsv.gz",
        region_data = "data/11_ghcnd_regions_years.tsv"
    output:
        file = "results/5_world_drought.png"
    shell:
        """
        {input.r_script} 
        """
