"""
    install_with_pip()

    Uses the `Conda.pip` method to install
    napari using pyqt5
"""
function install_with_pip()
    # https://napari.org/docs/0.4.0/
    Conda.pip_interop(true)
    Conda.pip("install","napari[pyqt5]")
end

"""
    install_with_conda()

    Uses `Conda.add` to install napari from
    conda-forge
"""
function install_with_conda()
    # https://anaconda.org/conda-forge/napari
    Conda.add(["pyqt", "napari"]; channel = "conda-forge")
end
