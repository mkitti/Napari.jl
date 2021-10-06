"""
    In order to send images to Python, we have to convert them to a primtive
    array. We overload view_image here for specific types which would be difficult
    to display in Napari otherwise
"""
module Image

# The main reason to have this in a discrete module is really to contain the imports
# until we can be more explicit about what we are importing
#
# In lieu of PR 876 in PyCall, we use NumPyArrays, to perform no-copy conversions into Python friendly arrays
# https://github.com/JuliaPy/PyCall.jl/pull/876 
using Images, FixedPointNumbers, PyCall, AxisArrays, ImageMetadata, NumPyArrays

import Napari: napari, view_image, add_image

# This module 

view_image(A::AbstractArray{C}, args...; kwargs...) where C <: Colorant{T,3} where T <: FixedPoint{F} where F =
    view_image(primitive_array(A), args...; kwargs...)
add_image(viewer, A::AbstractArray{C}, args...; kwargs...) where C <: Colorant{T,3} where T <: FixedPoint{F} where F =
    add_image(viewer, primitive_array(A), args...; kwargs...)

function primitive_array(A::AbstractArray{C}) where C <: Colorant{T,3} where T <: FixedPoint{F} where F
    # 1. Grab channel view which gets us Array{T,3}. This is a Base.ReinterpretArray
    # 2. Convert to Array{F,3}, still a Base.ReinterpretArray
    # 3. Permute dims such that the channels are the last dimension, without copying
    PermutedDimsArray( reinterpret(F,channelview(A)), (2,3,1))
end

view_image(A::AbstractArray{C}, args...; kwargs...) where C <: Colorant{T,4} where T <: FixedPoint{F} where F =
    view_image(primitive_array(A), args...; kwargs...)
add_image(viewer, A::AbstractArray{C}, args...; kwargs...) where C <: Colorant{T,4} where T <: FixedPoint{F} where F =
    add_image(viewer, primitive_array(A), args...; kwargs...)

function primitive_array(A::AbstractArray{C}) where C <: Colorant{T,4} where T <: FixedPoint{F} where F
    # 1. Grab channel view which gets us Array{T,3}. This is a Base.ReinterpretArray
    # 2. Convert to Array{F,3}, still a Base.ReinterpretArray
    # 3. Permute dims such that the channels are the last dimension, without copying
    PermutedDimsArray( reinterpret(F,channelview(A)), (2,3,1))
end

view_image(A::AbstractArray{C}, args...; kwargs...) where C <: Colorant{T,1} where T =
    view_image(primitive_array(A), args...; kwargs...)
add_image(viewer, A::AbstractArray{C}, args...; kwargs...) where C <: Colorant{T,1} where T = 
    add_image(viewer, primitive_array(A), args...; kwargs...)

function primitive_array(A::AbstractArray{C}) where C <: Colorant{T,1} where T <: FixedPoint{F} where F
    # 1. Grab channel view which gets us Array{T,3}. This is a Base.ReinterpretArray
    # 2. Convert to Array{F,3}, still a Base.ReinterpretArray
    reinterpret(F,channelview(A))
end
function primitive_array(A::AbstractArray{C}) where C <: Colorant{F, 1} where F <: AbstractFloat
    reinterpret(F,channelview(A))
end

view_image(A::AbstractArray{C}, args...; kwargs...) where C <: TransparentColor{Gray{F}, F} where F =
    view_image(primitive_array(A), args...; kwargs...)
add_image(A::AbstractArray{C}, args...; kwargs...) where C <: TransparentColor{Gray{F}, F} where F =
    add_image(primitive_array(A), args...; kwargs...)

function primitive_array(A::AbstractArray{C}) where C <: TransparentColor{Gray{F}, F} where F
    # Napari does not know how to combine alpha channel and gray
    primitive_array( RGBA.(A) )
end

"""
    view_image(img::ImageMeta, ...)

    This function adds the following keywords if not provided:
        channel_axis = axis with name :channel
        order = gives axes in order of :time, :channel, :y, :x
        axis_labels = axisnames(img)
        metadata = properties(img)
"""
function view_image(img::ImageMeta, args...; kwargs...)
    # ImageMeta might be from OMETIFF
    # For example, testimage("multi-channel-time-series.ome.tif")
    kwdict = Dict{Symbol,Any}(kwargs)

    if !haskey(kwdict, :metadata)
        kwdict[:metadata] = properties(img)
    end

    view_image( arraydata(img) , args... ; kwdict...)
end

"""
    add_image(viewer, img::ImageMeta, ...)

    This function adds the following keywords if not provided:
        channel_axis = axis with name :channel
        metadata = properties(img)

    Unlike view_image(img::ImageMeta, ...) it does change the
    order or axis_labels
"""
function add_image(viewer, img::ImageMeta, args...; kwargs...)
    # ImageMeta might be from OMETIFF
    # For example, testimage("multi-channel-time-series.ome.tif")
    kwdict = Dict{Symbol,Any}(kwargs)

    if !haskey(kwdict, :metadata)
        kwdict[:metadata] = properties(img)
    end

    add_image(viewer, arraydata(img) , args... ; kwdict...)
end


"""
    view_image(img::AxisArray{Gray{T}}, ...)

    This function adds the following keywords if not provided:
        channel_axis = axis with name :channel
        order = gives axes in order of :time, :channel, :y, :x
        axis_labels = axisnames(img)
"""
function view_image(img::AxisArray, args...; kwargs...)
    A = primitive_array( img )
    dims = collect( 1:ndims( img ) )
    dim_names = axisnames(img)
    time_dim = findfirst(in((:time, :T)), dim_names)
    channel_dim = findfirst(in((:channel, :C)), dim_names)
    kwdict = Dict{Symbol,Any}(kwargs)
    # If we have an image with (:y, :x, :channel, :time)
    # transform it to (:time, :channel, :y, :x)
    if !isnothing(time_dim)
        popat!(dims, time_dim)
        if !isnothing(channel_dim)
            popat!(dims, channel_dim)
            pushfirst!(dims, channel_dim)
            if !haskey(kwdict, :channel_axis)
                kwdict[:channel_axis] = channel_dim - 1
            end
        end
        pushfirst!(dims, time_dim)
        if !haskey(kwdict, :order)
           kwdict[:order] = dims .- 1
        end
    else
        # No time axis found
        if !isnothing(channel_dim)
            popat!(dims, channel_dim)
            pushfirst!(dims, channel_dim)
            if !haskey(kwdict, :channel_axis)
                kwdict[:channel_axis] = channel_dim - 1
            end
        end
        if !haskey(kwdict, :order)
            order = dims .- 1
        end
    end
    if !haskey(kwdict, :axis_labels)
        kwdict[:axis_labels] = String.(dim_names)
    end
    @info kwdict

    view_image(A, args... ; kwdict...)
end

"""
    add_image(viewer, img::AxisArrays{Gray{T},...})

    This function adds the channel_axis keyword if not provided.
    
    Unlike view_image(viewer, img::AxisArrays{Gray{T},...}) it does
    not change the order or add axis_labels.
"""
function add_image(viewer, img::AxisArray, args...; kwargs...)
    A = primitive_array( img )
    dims = collect( 1:ndims( img ) )
    dim_names = axisnames(img)
    time_dim = findfirst(in((:time, :T)), dim_names)
    channel_dim = findfirst(in((:channel, :C)), dim_names)
    kwdict = Dict{Symbol,Any}(kwargs)
    # If we have an image with (:y, :x, :channel, :time)
    # transform it to (:time, :channel, :y, :x)
    if !isnothing(time_dim)
        popat!(dims, time_dim)
        if !isnothing(channel_dim)
            popat!(dims, channel_dim)
            pushfirst!(dims, channel_dim)
            if !haskey(kwdict, :channel_axis)
                # We are going to permute the array
                kwdict[:channel_axis] = 1
            end
        end
        pushfirst!(dims, time_dim)
        # We permute the array since we are adding to an existing viewer
        @info "Permuting Dims"
        A = PermutedDimsArray(A, dims)
    else
        # No time axis found
        if !isnothing(channel_dim)
            popat!(dims, channel_dim)
            pushfirst!(dims, channel_dim)
            if !haskey(kwdict, :channel_axis)
                kwdict[:channel_axis] = channel_dim - 1
            end
        end
    end

    add_image(viewer, A, args... ; kwdict...)
end

function primitive_array(A::AxisArray{Gray{T},N}) where T <: FixedPoint{F} where {F,N}
    reinterpret(F, arraydata(A))
end
function primitive_array(A::AxisArray{T}) where T
    reinterpret(T, arraydata(A))
end

# Use NumPyArray for types with strides and a parent

view_image(img::PermutedDimsArray, args...; kwargs...) = view_image(NumPyArray(img), args...; kwargs...)
add_image(viewer, img::PermutedDimsArray, args...; kwargs...) = add_image(viewer, NumPyArray(img), args...; kwargs...)
view_image(img::SubArray, args...; kwargs...) = view_image(NumPyArray(img), args...; kwargs...)
add_image(viewer, img::SubArray, args...; kwargs...) = add_image(viewer, NumPyArray(img), args...; kwargs...)
view_image(img::Base.ReinterpretArray, args...; kwargs...) = view_image(NumPyArray(img), args...; kwargs...)
add_image(viewer, img::Base.ReinterpretArray, args...; kwargs...) = add_image(viewer, NumPyArray(img), args...; kwargs...)
view_image(img::Base.ReshapedArray, args...; kwargs...) = view_image(NumPyArray(img), args...; kwargs...)
add_image(viewer, img::Base.ReshapedArray, args...; kwargs...) = add_image(viewer, NumPyArray(img), args...; kwargs...)

end # PyConvert module end