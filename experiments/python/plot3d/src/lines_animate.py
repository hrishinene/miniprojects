import numpy as np
import plotly.graph_objects as go

# Number of animation steps
steps = 30  

# Starting line segment: (0,0,0) → (1,0,0)
x_start, y_start, z_start = 0, 0, 0
x_end, y_end, z_end = 1, 0, 0

# Target line segment: (0,1,0) → (1,1,1)
x_start_t, y_start_t, z_start_t = 0, 1, 0
x_end_t, y_end_t, z_end_t = 1, 1, 1

# Generate frames
frames = []
for i in range(steps + 1):
    t = i / steps  # interpolation factor
    xs = (1-t)*x_start + t*x_start_t
    ys = (1-t)*y_start + t*y_start_t
    zs = (1-t)*z_start + t*z_start_t

    xe = (1-t)*x_end + t*x_end_t
    ye = (1-t)*y_end + t*y_end_t
    ze = (1-t)*z_end + t*z_end_t

    frames.append(go.Frame(data=[
        go.Scatter3d(
            x=[xs, xe], y=[ys, ye], z=[zs, ze],
            mode="lines+markers",
            line=dict(color="blue", width=6),
            marker=dict(size=4)
        )
    ]))

# Initial trace (first frame)
init_trace = go.Scatter3d(
    x=[x_start, x_end],
    y=[y_start, y_end],
    z=[z_start, z_end],
    mode="lines+markers",
    line=dict(color="blue", width=6),
    marker=dict(size=4)
)

# Layout with animation controls
layout = go.Layout(
    scene=dict(
        xaxis=dict(range=[-0.5, 1.5]),
        yaxis=dict(range=[-0.5, 1.5]),
        zaxis=dict(range=[-0.5, 1.5]),
    ),
    updatemenus=[dict(type="buttons",
                      showactive=False,
                      buttons=[dict(label="Play",
                                    method="animate",
                                    args=[None, dict(frame=dict(duration=100, redraw=True),
                                                     fromcurrent=True, mode="immediate")])])]
)

fig = go.Figure(data=[init_trace], frames=frames, layout=layout)
fig.show()

