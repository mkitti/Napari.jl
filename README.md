# Napari.jl

This project is a Julia language wraper around [Napari](https://github.com/napari/napari).

## Installation

First, we recommend that you configure [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) and install [Napari](https://github.com/napari/napari) into the Python environment
used by PyCall.jl. You can try either the `Napari.install_with_pip()` or `Napari.install_with_conda()` methods although these are not tested.

This package is currently not in the Julia registry.

```julia
using Pkg
Pkg.add("https://github.com/mkitti/Napari.jl.git")
Napari.install_with_pip() # If you have not installed Napari yet
```

## Quick Start

```julia
using Napari
@view_image Napari.astronaut()
```

## Usage

Napari.jl exports `napari` which is a `PyObject` referring to the `napari` module as imported by [PyCall.jl](https://github.com/JuliaPy/PyCall.jl). This means that you can use the Pythonic syntax as provided by PyCall.

```julia
using Napari

random_noise = rand(UInt8, 512,512)
napari.view_image( random_noise )

using PyCall

astronaut = pyimport("skimage.data").astronaut()
viewer = napari.view_image(astronaut)
viewer.add_image(astronaut[:,:,1])
```

Compare this to using Napari from Python via this Julia script:
```julia
using PyCall

py"""
from skimage import data
import napari

astronaut = data.astronaut()
napari.view_image( astronaut )
"""
```
You may notice that the label of the image layer is "astronaut" while using Python but is just "Image" when using Julia. This is because the magic naming of the layer is dependent on Python's `inspect` package, which does not extend into Julia.

To improve the situation, Napari.jl provides a set of macros that provides similar magic naming functionality.

The first macro is `@namekw` which just adds a name keyword argument to any function.
```julia
using PyCall
astronaut = pyimport("skimage.data").astronaut()

viewer = @namekw napari.view_image( astronaut ) # Adds name = "astronaut" keyword argument
@namekw viewer.add_labels( astronaut[:,:,1] .> 100 ) # Adds name = "astronaut[:,:,1] .> 100" keyword argument
```

    :image,
    :points,
    :labels,
    :shapes,
    :surface,
    :vectors,
    :tracks

For convenience, this package also provides and exports the following macros.

`@view_*`:
* `@view_image(expr; kwargs...)` - Equivalent to `napari.view_image(expr; name = string( :(expr) ), kwargs... )`
* `@view_points(expr; kwargs...)` - Equivalent to `napari.view_points(expr; name = string( :(expr) ), kwargs... )`
* `@view_labels(expr; kwargs...)` - Equivalent to `napari.view_labels(expr; name = string( :(expr) ), kwargs... )`
* `@view_shapes(expr; kwargs...)` - Equivalent to `napari.view_shapes(expr; name = string( :(expr) ), kwargs... )`
* `@view_surface(expr; kwargs...)` - Equivalent to `napari.view_surface(expr; name = string( :(expr) ), kwargs... )`
* `@view_vectors(expr; kwargs...)` - Equivalent to `napari.view_vectors(expr; name = string( :(expr) ), kwargs... )`
* `@view_tracks(expr; kwargs...)` - Equivalent to `napari.view_tracks(expr; name = string( :(expr) ), kwargs... )`

`@add_*`:
* `@add_image(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_image(expr; kwargs...)`
* `@add_points(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_points(expr; kwargs...)`
* `@add_labels(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_labels(expr; kwargs...)`
* `@add_shapes(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_shapes(expr; kwargs...)`
* `@add_surface(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_surface(expr; kwargs...)`
* `@add_vectors(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_vectors(expr; kwargs...)`
* `@add_tracks(viewer, expr; kwargs...)` - Equvivalent to `viewer.add_tracks(expr; kwargs...)`

```julia
using PyCall
astronaut = pyimport("skimage.data").astronaut()

using Napari
viewer = @view_image(astronaut) # The macros can be used with parentheses
@add_labels viewer astronaut[:,:,1] .> 100 # They macros can also be used without parentheses and commas
```

## Advanced

This package defaults to using pyqt5 and uses `PyCall.pygui_start(:qt5)` to initialize the the QT event loop.
Set environmental variable `NAPARI_JL_QT` to "false" to disable this. In that case, the GUI event loop must
be initialized manually.

## History

It is based around an earlier script, `napari.jl`, by Mark Kittisopikul that was posted as a [gist](https://gist.github.com/mkitti/2f7c5fc3d3f8b0d15dd13f6d67b0e73d) in Janaruy 2020.
