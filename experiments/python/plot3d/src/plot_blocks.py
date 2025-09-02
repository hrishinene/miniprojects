import plotly.graph_objects as go

# Define block corners (x, y, z)
# Let's make a block from (0,0,0) to (2,1,3)
x = [0, 2, 2, 0, 0, 2, 2, 0]
y = [0, 0, 1, 1, 0, 0, 1, 1]
z = [0, 0, 0, 0, 3, 3, 3, 3]

# Define the vertices for each triangular face of the block
i = [0, 0, 0, 3, 4, 7, 6, 6, 5, 1, 2, 2]
j = [1, 3, 4, 2, 5, 4, 7, 2, 6, 5, 6, 3]
k = [3, 4, 5, 7, 6, 6, 5, 6, 7, 6, 7, 7]

fig = go.Figure(data=[
    go.Mesh3d(
        x=x, y=y, z=z,
        i=i, j=j, k=k,
        opacity=0.9,
        color='lightblue',
        flatshading=True
    )
])

fig.update_layout(
    scene=dict(
        xaxis_title='X',
        yaxis_title='Y',
        zaxis_title='Z'
    )
)

fig.show()