"""

"""

export @namekw

"""
    @namekw func(expr)

    Alters a function call to include a name keyword based
        on the expression for the first argument.

    @namekw( func(expr) ) == func(expr; name = string( :(expr) ) )
"""
macro namekw(expr)
    ( isa(expr,Expr) && expr.head == :call ) ||
        error("@namekw must be used on a method call.")
    push!( expr.args, Expr( :kw, :name, string(expr.args[2]) ) )
    esc( expr )
end

"This macro is meant to replace the function of napari.utils.naming.magic_name"
function call_with_name_keyword(func, data, kwargs...)
    # We need to replace the function of magic_name
    local name_given = any([a.args[1] == :name for a in kwargs if isa(a,Expr)])
    local x = [esc(kw) for kw in kwargs]
    if name_given
        return :( $(func)( $( esc(data ) ); $(x...) ) )
    else
        local name = string(data)
        return :( $(func)( $( esc(data) ); name=$name, $(x...) ) )
    end
end

# We duplicate this function 
"This macro is meant to replace the function of napari.utils.naming.magic_name"
function call_viewer_with_name_keyword(func, viewer, data, kwargs...)
    # We need to replace the function of magic_name
    local name_given = any([a.args[1] == :name for a in kwargs if isa(a,Expr)])
    local x = [esc(kw) for kw in kwargs]
    if name_given
        return :( $(func)( $( esc(viewer) ), $( esc(data) ); $(x...) ) )
    else
        local name = string(data)
        return :( $(func)( $( esc(viewer) ), $( esc(data) ); name=$name, $(x...) ) )
    end
end


#= 
macro view_image(image, kwargs...)
    call_with_name_keyword( :( napari_ref[].view_image ),
                           image, kwargs...)
end
 =#

# see napari/view_layers.py
# see napari.layers.NAMES
for layer in layers
    local macro_name = Symbol("view_", layer)
    # local view = Expr( :. , :(napari_ref[]), QuoteNode( macro_name ) )
    local view = QuoteNode( macro_name )
    eval( Expr( :export, Symbol('@', macro_name) ) )
    @eval begin
        """
            @view_{layer}(expr)

            Equivalent to napari.view_*(expr; name = string( :(expr) )).
            layer is one of image, points, labels, shapes, surface, vectors
            or tracks.
        """
        macro $macro_name($layer, kwargs...)
            call_with_name_keyword( $view , $layer, kwargs... )
        end
    end

    local macro_name = Symbol("add_", layer)
    local add = QuoteNode(macro_name)
    eval( Expr( :export, Symbol('@', macro_name) ) )
    @eval begin
        """
            @add_{layer}(viewer, expr)

            Equivalent to viewer.add_*(expr; name = string( :(expr) ))
            viewer is a napari.viewer.Viewer created by napari.Viewer()
            layer is one of image, points, labels, shapes, surface, vectors
            or tracks.
        """
        macro $macro_name(viewer, data, kwargs...)
            call_viewer_with_name_keyword( $add, viewer, data, kwargs... )
        end
    end
end