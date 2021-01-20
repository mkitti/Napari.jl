"""
    Viewer(args...; kwargs...)

    Call napari.Viewer(args...; kwargs...)
"""
Viewer(args...; kwargs...) = napari.Viewer(args...; kwargs...)

"""
    Viewer(f::Function, args...; kwargs...)

    Call f(Napari.Viewer(args...; kwargs...). Enables the following
    code pattern:

    ```julia
    Napari.Viewer() do v
        @add_image( v, zeros(1024,1024) )
        @add_iamge( v, Napari.astronaut() )
    end
    ```
"""
Viewer(f::Function, args...; kwargs...) = f(Viewer(args...; kwargs...))
