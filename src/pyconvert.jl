"""
    In order to send images to Python, we have to convert them to a primtive
    array. This submodule overloads PyObject and dispatches to primitive_array
"""
module PyConvert

using Images, FixedPointNumbers, PyCall, AxisArrays, ImageMetadata

function PyCall.PyObject(A::AbstractArray{C}) where C <: Colorant{T} where T <: FixedPoint{F} where F
    PyCall.PyObject( primitive_array( A ) )
end

function primitive_array(A::AbstractArray{C}) where C <: Colorant{T,3} where T <: FixedPoint{F} where F
    # 1. Grab channel view which gets us Array{T,3}. This is a Base.ReinterpretArray
    # 2. Convert to Array{F,3}, still a Base.ReinterpretArray
    # 3. Permute dims such that the channels are the last dimension, copy
    permutedims( reinterpret(F,channelview(A)), (2,3,1)) 
end

function primitive_array(A::AbstractArray{C}) where C <: Colorant{T,4} where T <: FixedPoint{F} where F
    # 1. Grab channel view which gets us Array{T,3}. This is a Base.ReinterpretArray
    # 2. Convert to Array{F,3}, still a Base.ReinterpretArray
    # 3. Permute dims such that the channels are the last dimension, copy
    permutedims( reinterpret(F,channelview(A)), (2,3,1)) 
end

function primitive_array(A::AbstractArray{C}) where C <: Colorant{T,1} where T <: FixedPoint{F} where F
    # 1. Grab channel view which gets us Array{T,3}. This is a Base.ReinterpretArray
    # 2. Convert to Array{F,3}, still a Base.ReinterpretArray
    copy( reinterpret(F,channelview(A)) )
end

function primitive_array(A::AbstractArray{C}) where C <: TransparentColor{Gray{F}, F} where F
    # Napari does not know how to combine alpha channel and gray
    primitive_array( RGBA.(A) )
end


function primitive_array(img::ImageMeta)
    # ImageMeta might be from OMETIFF
    # For example, testimage("multi-channel-time-series.ome.tif")
    A = primitive_array( arraydata(img) )
    dims = collect( 1:ndims( img ) )
    dim_names = axisnames(img)
    time_dim = findfirst(==(:time), dim_names)
    channel_dim = findfirst(==(:channel), dim_names)
    # If we have an image with (:y, :x, :channel, :time)
    # transform it to (:time, :channel, :y, :x)
    if !isnothing(time_dim)
        popat!(dims, time_dim)
        if !isnothing(channel_dim)
            popat!(dims, channel_dim)
            pushfirst!(dims, channel_dim)
        end
        pushfirst!(dims, time_dim)
        A = permutedims(A, dims)
    end
    A
end

function primitive_array(A::AxisArray{Gray{T},N}) where T <: FixedPoint{F} where {F,N}
    copy( reinterpret(F, A) )
end

end # PyConvert module end