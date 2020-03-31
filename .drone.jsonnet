local release = "20.04";
local distro = "buster";

local build(board, arch, mode) = {
    local base_image = board + "-base.img",
    local suffix = if mode == "sd" then "-sd" else "",
    local size = if mode == "sd" then "10M" else "3G",
    local image = "syncloud-" + board  + suffix + "-" + distro + "-" + release + ".img",

    kind: "pipeline",
    name: board + "-" + mode,

    platform: {
        os: "linux",
        arch: "amd64"
    },
    steps: [
    {
        name: "extract",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/extract.sh " + board + " " + base_image
        ],
        privileged: true
    },
    {
        name: "boot",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/boot.sh " + board  + " " + image + " " + size
        ],
        privileged: true
    },
    if mode == "boot" then {} else
    {
        name: "rootfs",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/rootfs.sh " + board + " " + arch + " " + image + " " + release + " " + distro
        ],
        privileged: true
    },
    {
        name: "zip",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./tools/zip.sh " + image
        ],
        privileged: true
    },
    {
        name: "artifact",
        image: "appleboy/drone-scp",
        settings: {
            host: {
                from_secret: "artifact_host"
            },
            username: "artifact",
            key: {
                from_secret: "artifact_key"
            },
            command_timeout: "2m",
            target: "/home/artifact/repo/image",
            source: image + "*.xz"
        }
    },
    {
        name : "cleanup",
        image: "syncloud/build-deps-amd64",
        commands: [
            "./cleanup.sh"
        ],
        privileged: true,
        when: {
            status: [ "failure", "success" ]
        }
    }]
};

[
//build("cubieboard2", "arm", "all"),
//build("cubieboard", "arm", "all"),
//build("beagleboneblack", "arm", "all"),
//build("bananapim3", "arm", "all"),
//build("rock64", "arm", "all"),
//build("helios4", "arm", "all"),
//build("raspberrypi3", "arm", "all"),
//build("raspberrypi4", "arm", "all"),
//build("raspberrypi2", "arm", "all"),
//build("odroid-xu3and4", "arm", "all"),
//build("odroid-xu3and4", "arm", "sd"),
//build("odroid-c2", "arm", "all"),
//build("odroid-u3", "arm", "all"),
//build("bananapim2", "arm", "all"),
//build("bananapim1", "arm", "all"),
//build("cubietruck", "arm", "all"),
//build("tinker", "arm", "all"),
//build("odroid-n2", "arm", "all"),
//build("lime2", "arm", "all"),
build("amd64", "amd64", "all")
]
