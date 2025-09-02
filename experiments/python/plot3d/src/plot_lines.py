# import plotly.graph_objects as go

# segments = [
#     ((0, 0, 0), (1, 1, 1)),
#     ((1, 1, 1), (2, 0, 1)),
#     ((0, 1, 0), (1, 0, 2))
# ]

# fig = go.Figure()

# for start, end in segments:
#     fig.add_trace(go.Scatter3d(
#         x=[start[0], end[0]],
#         y=[start[1], end[1]],
#         z=[start[2], end[2]],
#         mode='lines+markers'
#     ))

# fig.show()


import plotly.graph_objects as go
# import numpy as np

# Example: define lines with start and end points
lines = [
    {"start": (0, 0, 0), "end": (1, 1, 1)},
    {"start": (1, 1, 1), "end": (2, 0, 1)},
    {"start": (0, 1, 0), "end": (1, 0, 2)},
]

fig = go.Figure()

# Draw each line
for idx, line in enumerate(lines, start=1):
    x = [line["start"][0], line["end"][0]]
    y = [line["start"][1], line["end"][1]]
    z = [line["start"][2], line["end"][2]]
    
    # Add line
    fig.add_trace(go.Scatter3d(
        x=x, y=y, z=z,
        mode='lines',
        line=dict(width=5),
        name=f"Line {idx}"
    ))
    
    # Compute midpoint for annotation
    mid = (
        (x[0] + x[1]) / 2,
        (y[0] + y[1]) / 2,
        (z[0] + z[1]) / 2
    )
    
    # Add text label
    fig.add_trace(go.Scatter3d(
        x=[mid[0]], y=[mid[1]], z=[mid[2]],
        mode='text',
        text=[str(idx)],
        textposition='middle center',
        textfont=dict(size=14, color='red'),
        showlegend=False
    ))

fig.update_layout(
    scene=dict(
        xaxis_title='X', yaxis_title='Y', zaxis_title='Z'
    )
)

fig.show()

