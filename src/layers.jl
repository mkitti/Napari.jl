# Create Napari.view_* and Napari.add_* that alias into the Python versions
# This allows Julia code to take advantage of multiple dispatch by overloading
# these functions for specific types.

# The code below generates the add_* and view_* functions in the comments below
for layer in layers
    local view_name = Symbol("view_", layer)
    local add_name = Symbol("add_", layer)
    @eval begin
        $view_name( data, args...; kwargs... ) = napari_ref[].$view_name( data, args...; kwargs... )
        $add_name( viewer, data, args...; kwargs... ) = viewer.$add_name( data, args...; kwargs... )
    end
end

# view_image(   data, args...; kwargs... ) = napari_ref[].view_image(   data, args...; kwargs... )
# view_points(  data, args...; kwargs... ) = napari_ref[].view_points(  data, args...; kwargs... )
# view_labels(  data, args...; kwargs... ) = napari_ref[].view_labels(  data, args...; kwargs... )
# view_shapes(  data, args...; kwargs... ) = napari_ref[].view_shapes(  data, args...; kwargs... )
# view_surface( data, args...; kwargs... ) = napari_ref[].view_surface( data, args...; kwargs... )
# view_vectors( data, args...; kwargs... ) = napari_ref[].view_vectors( data, args...; kwargs... )
# view_tracks(  data, args...; kwargs... ) = napari_ref[].view_tracks(  data, args...; kwargs... )

# add_image(   viewer, data, args...; kwargs... ) = napari_ref[].add_image(   viewer, data, args...; kwargs... )
# add_points(  viewer, data, args...; kwargs... ) = napari_ref[].add_points(  viewer, data, args...; kwargs... )
# add_labels(  viewer, data, args...; kwargs... ) = napari_ref[].add_labels(  viewer, data, args...; kwargs... )
# add_shapes(  viewer, data, args...; kwargs... ) = napari_ref[].add_shapes(  viewer, data, args...; kwargs... )
# add_surface( viewer, data, args...; kwargs... ) = napari_ref[].add_surface( viewer, data, args...; kwargs... )
# add_vectors( viewer, data, args...; kwargs... ) = napari_ref[].add_vectors( viewer, data, args...; kwargs... )
# add_tracks(  viewer, data, args...; kwargs... ) = napari_ref[].add_tracks(  viewer, data, args...; kwargs... )

# Place holder modules mirroring upstream
# I'm not really sure if this is actually going to be useful
module Layers

    # module Image
    include("image.jl")

    module Labels
    end
    module Points
    end
    module Shapes
    end
    module Surface
    end
    module Tracks
    end
    module Utils
    end
    module Vectors
    end
end

