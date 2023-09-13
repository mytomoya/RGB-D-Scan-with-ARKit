
│       ├── rgb_1.jpg
│       └── ...
└── 2/
    ├── Confidence/
    ├── Frame/
    └── RGB/
```

`frame_n.json` contains the following information for the `n`-th frame:

```json
{
    "depth_map": {
        "width": "width of the depth map",
        "height": "height of the depth map",
        "values": [
            "depth map values flattened into a 1D array"
        ]
    },
    "intrinsic": [
        "3 x 3 camera intrinsic matrix"
    ],
    "view_matrix": [
        "4 x 4 view matrix"
    ],
    "frame_number": "frame number"
}
```


## Known Issues

- The number of saved frames shown on the top left of the app is not accurate. Sometimes it shows a larger number than the actual number of saved frames.
