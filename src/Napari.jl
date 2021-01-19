module Napari

export napari


using PyCall
using Conda

# Napari module, use this instead of the napari global
const napari = PyNULL()
const napari_ref = Ref{PyObject}()
# PyQt5.QtWidgets.QApplication
const qapp_obj_ref = Ref{PyObject}()

const layers = (
    :image,
    :points,
    :labels,
    :shapes,
    :surface,
    :vectors,
    :tracks
)
# We want to precompile the layer commands, so we declare this statically
# but the above constant should be effectively the same as below
# const layers = Symbol.( (napari_ref[].layers.NAMES...,) )

include("layers.jl")
include("layer_name_macros.jl")
include("viewer.jl")
include("install.jl")

function __init__(qt = parse(Bool, get( ENV, "NAPARI_JL_QT", "true") ) )
    try
        # We need to coordinate between PyCall and Napari
        # https://github.com/JuliaPy/PyCall.jl/blob/master/src/gui.jl#L140
        # https://github.com/napari/napari/blob/master/napari/_qt/event_loop.py

        #napari_ref[] = pyimport("napari")
        napari_ref[] = pyimport_conda("napari", "napari", "conda-forge")

        # The global napari is only meant to be used for convenience at the REPL
        # use napari_ref[] internally and otherwise
        copy!(napari,napari_ref[])

        @info "napari version" version = napari_ref[].__version__
        @info dirname(napari.__file__)
        if qt
            pygui_start(:qt5)
            # Needed to kickstart Qt5 for some reason
            #qapp_obj_ref[] = pyimport("qtpy.QtWidgets").QApplication([""])
            QApplication = pyimport("qtpy.QtWidgets").QApplication
            qapp_obj_ref[] = QApplication.instance()
            if isequal( qapp_obj_ref[] , PyObject(nothing) )
                # @info "Creating QApplication"
                # See gui_qt in napari._qt.event_loop
                Qt = pyimport("qtpy.QtCore").Qt
                QApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
                qapp_obj_ref[] = QApplication( [] )
                qapp_obj_ref[].setApplicationName("napari")
            end
        else
            @warn """pygui_start(:qt5) not run. Start the event loop manually.
                     You may need to initailize qtpy.QtWidgets.QApplication.
                     See environmental variable NAPARI_JL_NOQT"""
        end
    catch err
        @warn """Napari.jl has failed to import qtpy and napari from Python.
                 Please make sure these are installed. See the
                 Napari.install_with_pip() and Napari.install_with_conda()
                 methods of this package.
        """
        @debug err
        rethrow(err)
    end
end

function install_at_exit_handler()
    atexit( () -> qapp_obj_ref[] )
end

function startup_logo(time = 1)
    # imports
    QPixmap = pyimport("qtpy.QtGui").QPixmap
    Qt = pyimport("qtpy.QtCore").Qt
    QSplashScreen = pyimport("qtpy.QtWidgets").QSplashScreen
    # Almost verbatim from napari._qt.eventloop
    logopath = joinpath( dirname(napari_ref[].__file__), "resources", "logo.png" )
    pm = QPixmap(logopath).scaled(
        360, 360, Qt.KeepAspectRatio, Qt.SmoothTransformation
    )
    splash_widget = QSplashScreen(pm)
    splash_widget.show()
    qapp_obj_ref[]._splash_widget = splash_widget
    @async begin
        sleep(time)
        splash_widget.close()
    end
    splash_widget
end

function astronaut()
    pyimport("skimage.data").astronaut()
end



end