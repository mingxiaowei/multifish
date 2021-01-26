
registration_container = "/groups/scicompsoft/home/rokickik/dev/multifish/containers/bigstream/out.sif"

process cut_tiles {
    container = registration_container

    input:
    val ref_img_path
    val ref_img_subpath
    val tiles_dir
    val xy_stride
    val xy_overlap
    val z_stride
    val z_overlap

    output:
    val "${tiledir}/0/coords.txt"

    script:
    """
    /app/scripts/waitforpaths.sh ${ref_img_path}${ref_img_subpath}
    /entrypoint.sh cut_tiles $ref_img_path $ref_img_subpath $tiles_dir $xy_stride $xy_overlap $z_stride $z_overlap
    """
}

process coarse_spots {
    container = registration_container

    input:
    val img_path
    val img_subpath
    val output_file
    val radius
    val spotNum

    output:
    val output_file

    script:
    """
    /app/scripts/waitforpaths.sh ${img_path}${img_subpath}
    /entrypoint.sh spots coarse $img_path $img_subpath $output_file $radius $spotNum
    """

}

process ransac {
    container = registration_container

    input:
    val fixed_spots
    val moving_spots
    val output_dir
    val output_file
    val cutoff
    val threshold

    output:
    val "$output_dir/$output_file"

    script:
    """
    /app/scripts/waitforpaths.sh $fixed_spots $moving_spots
    /entrypoint.sh ransac $fixed_spots $moving_spots $output_dir/$output_file $cutoff $threshold
    """
}

process apply_transform {
    container = registration_container

    input:
    val cpus
    val ref_img_path
    val ref_img_subpath
    val mov_img_path
    val mov_img_subpath
    val txm_path
    val output_path
    val points_path

    output:
    tuple val(output_path), val(ref_img_subpath)

    cpus "$cpus"

    script:
    """
    /app/scripts/waitforpaths.sh ${ref_img_path}${ref_img_subpath} ${mov_img_path}${mov_img_subpath}
    /entrypoint.sh apply_transform_n5 $ref_img_path $ref_img_subpath $mov_img_path $mov_img_subpath $txm_path $output_path $points_path
    """
}

process spots_for_tile {
    container = registration_container

    input:
    val img_path
    val img_subpath
    val tile
    val output_file
    val radius
    val spotNum

    output:
    val "$tile/$output_file"

    script:
    """
    /app/scripts/waitforpaths.sh ${img_path}${img_subpath}
    /entrypoint.sh spots $tile/coords.txt $img_path $img_subpath $tile/$output_file $radius $spotNum
    """

}

process interpolate_affines {
    container = registration_container

    input:
    val all_tiles
    val tiles_dir

    output:
    val "done"

    script:
    """
    /entrypoint.sh interpolate_affines $tiles_dir
    """
}


process deform {
    container = registration_container

    input:
    val interpolation
    val tile
    val img_path
    val img_subpath
    tuple val(ransac_affine), val(ransac_affine_subpath)
    val deform_iterations
    val deform_auto_mask

    output:
    val output_file

    script:
    //ransac_affine = affine_big.map { t -> t[0] }
    //subpath = affine_big.map { t -> t[1] }
    """
    /app/scripts/waitforpaths.sh ${img_path}${img_subpath} ${ransac_affine}/${ransac_affine_subpath}
    /entrypoint.sh $img_path $img_subpath $ransac_affine $ransac_affine_subpath \
            $tile/coords.txt $tile/warp.nrrd $tile/ransac_affine.mat \
            $tile/final_lcc.nrrd $tile/invwarp.nrrd \
            $deform_iterations $deform_auto_mask
    """
}
