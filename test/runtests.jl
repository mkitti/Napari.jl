using Napari
using PyCall
using TestImages
using Test

try
    global skimagedata = pyimport("skimage.data")
    global astronaut = skimagedata.astronaut()
    global moon = skimagedata.moon()
    global camera = skimagedata.camera()
    global MagickMock = pyimport("unittest.mock").MagicMock
catch err
    @info "Napari.jl tests use data from skimage.data, but they could not be loaded"
    rethrow(err)
end

@testset "Napari.jl" begin
    @testset "PyCall and Python environment" begin
       @test py"""
       from skimage import data
       import napari

       astronaut = data.astronaut()
       viewer = napari.view_image( astronaut )
       viewer.close()
       """ === nothing
    end

    @testset "PyObject Interface" begin
        viewer = napari.Viewer() 
        @test viewer isa PyObject
        @test viewer.add_image( astronaut ) isa PyObject
        @test viewer.add_image( moon ) isa PyObject
        @test viewer.add_image( camera ) isa PyObject
        viewer.close()
        viewer = napari.view_image( astronaut , name = "Eileen Collins" )
        @test viewer isa PyObject
        viewer.close()
    end

    @testset "@namekw" begin
        viewer = @namekw napari.view_image( astronaut )
        @test viewer isa PyObject
        @test ( @namekw viewer.add_image( moon ) ) isa PyObject
        @test ( @namekw viewer.add_image( camera ) ) isa PyObject
        viewer.close()
    end

    @testset "Add and View Macros" begin
        viewer = @view_image astronaut
        @test viewer isa PyObject
        viewer.close()
        viewer = @view_image( astronaut, name ="Eileen Collins" )
        @test viewer isa PyObject
        @test @add_image(viewer, moon) isa PyObject
        @test @add_image(viewer, camera) isa PyObject
    end

    @testset "TestImages" begin
        viewer = MagickMock(napari.Viewer)
        for f in TestImages.remotefiles[1:10]
            @info f
            @test viewer.add_image( testimage(f), name=f) isa PyObject
        end
        for f in TestImages.remotefiles[11:20]
            @info f
            @test viewer.add_image( testimage(f), name=f) isa PyObject
        end
        for f in TestImages.remotefiles[21:30]
            @info f
            @test viewer.add_image( testimage(f), name=f) isa PyObject
        end
        for f in TestImages.remotefiles[31:40]
            @info f
            @test viewer.add_image( testimage(f), name=f) isa PyObject
        end
        for f in TestImages.remotefiles[41:end]
            @info f
            @test viewer.add_image( testimage(f), name=f) isa PyObject
        end
        @info "Shepp Logan"
        @test viewer.add_image( TestImages.shepp_logan(512, 512) ) isa PyObject
    end
end

function view_all_test_images()
    viewer = napari.Viewer()
    for (i,f) in enumerate(TestImages.remotefiles)
        @add_image(viewer, testimage(f), name="$i: $f") 
    end
end
