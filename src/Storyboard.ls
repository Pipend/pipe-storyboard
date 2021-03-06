require! \keyboardjs
{filter, find, fold, id, is-it-NaN, map, keys, Obj, obj-to-pairs, pairs-to-obj, Str} = require \prelude-ls
{is-empty-object, is-equal-to-object} = require \prelude-extension
{DOM:{div, input}, Children, clone-element, create-class, create-factory} = require \react
require! \react-selectize
SimpleSelect = create-factory react-selectize.SimpleSelect
MultiSelect = create-factory react-selectize.MultiSelect
LabelledComponent = create-factory require \./LabelledComponent

# on-hotkeys :: [String] -> (Event -> ()) -> Unbind :: () -> ()
on-hotkeys = (hotkeys, listener) ->

    # wrapped-listener :: Event -> ()
    wrapped-listener = (e) -> listener e; e.prevent-default!

    keyboardjs.bind hotkeys, wrapped-listener
    -> keyboardjs.unbind hotkeys, wrapped-listener

module.exports = create-class do

    display-name: \Storyboard

    # get-default-props :: a -> Props
    get-default-props: ->
        /*
        Control :: {
            name :: String, 
            type :: String, 
            label :: String,
            placeholder :: String, 
            options: [String], 
            multi: Boolean,
            tether :: Boolean,
            default-value :: a, 
            ui-value-from-state :: State -> UIValue, 
            state-from-ui-value :: UIValue -> State', 
            parameters-from-ui-value :: UIValue -> Parameters, where Parameters :: Map Name, Value
            render? :: UIValue -> (UIValue -> ()) -> ReactElement
        }
        */
        cache: 3600
        class-name: ""
        controls: [] # [Control]
        extras: {}
        parameters: {}
        state: {} # state :: State
        style: {}
        url: undefined # String
        
        # on-change :: State -> ()
        on-change: (state) !-> 

        # on-execute :: Parameters -> Boolean -> ()
        on-execute: ((parameters, will-execute) !-> )

        # on-reset :: () -> ()
        on-reset: (!->)

    # render :: a -> ReactElement
    render: ->
        {change, controls, parameters} = @get-computed-state!

        div do 
            class-name: "storyboard #{@props.class-name}"
            style: @props.style

            # FORM
            div do 
                class-name: \form, 

                controls |> map (control) ~>
                    {name, label, default-value, placeholder, render, ui-value-from-state, state-from-ui-value}? = control
                    
                    # LABELLED COMPONENT
                    LabelledComponent do 
                        key: name
                        label: label
                        show-label: !!label

                        # CUSTOM INPUT CONTROL
                        render do 
                            (ui-value-from-state @props.state) ? default-value
                            (new-ui-value) ~>
                                @props.on-change {} <<< @props.state <<< (state-from-ui-value new-ui-value)

                # BUTTONS
                div do
                    class-name: \buttons

                    # RESET BUTTON
                    div do 
                        class-name: \button
                        on-click: ~> @reset!
                        \Reset

                    # SEARCH BUTTON
                    div do 
                        class-name: "button #{if change then 'highlight' else ''}"
                        on-click: ~> @execute!
                        \Search

            # CHILDREN
            div do 
                class-name: \children

                # pass parameters to all the children (stories)
                Children.map do 
                    @props.children
                    (child) ~>

                        # STORY | LAYOUT | STORYBOARD
                        clone-element do 
                            child
                            cache: child.props?.cache ? @props.cache
                            extras: {} <<< @props.extras <<< child.props.extras
                            parameters: {} <<< @state.parameters <<<
                                refresh-count: value: @state.refresh-count
                            url: child.props?.url ? @props.url

    # get-initial-state :: () -> UIState
    get-initial-state: -> 
        parameters: {}
        refresh-count: 0

    # get-computed-state :: () -> ComputedState :: {controls :: [Control], parameters :: Parameters}
    get-computed-state: ->

        # update controls with defaults for the (ui-value-from-state, state-from-ui-value & parameters-from-ui-value) functions
        controls = @props.controls |> map (control) ~>
            {name, type, placeholder, options, tether, multi}? = control

            # handle cases where the state value or the ui value may be a string especially in the case of html input controls
            # this way the user doesn't need to pass string representation of the type in default-value prop
            # parser :: StateValue -> UIValue
            parser = match type
                | \number => (n) -> 
                    result = parse-float n
                    if is-it-NaN result then undefined else result

                | \checkbox => (b) ->
                    if typeof b == \string
                        match b
                            | \true => true
                            | \false => false
                            | _ => undefined
                    else
                        b

                | _ => id

            # render :: UIValue -> (UIValue -> ()) -> ReactElement
            render = control.render ? (value, on-change) ->
                switch type
                | \select =>
                    (if multi then MultiSelect else SimpleSelect) do 
                        key: name
                        tether: tether
                        placeholder: placeholder
                        value: 
                            | typeof value == \undefined => undefined
                            | _ => 
                                label: value
                                value: value
                        values:
                            | typeof value == \undefined => undefined
                            | _ => 
                                value
                                |> Str.split \,
                                |> filter -> !!it
                                |> map -> label: it, value: it
                        options: options |> map ~> label: it, value: it
                        on-value-change: ({value}?) ~> on-change value
                        on-values-change: (values) ~> 
                            on-change do
                                if !!values
                                    values 
                                    |> map (.value) 
                                    |> Str.join \,
                                else
                                    undefined

                | _ =>
                    input {
                        key: name
                        type
                        placeholder
                        on-change: ({current-target}) ~>

                            # f :: DOMElement -> UIValue
                            f = match type
                                | \checkbox => (.checked)
                                | _ => (.value)

                            on-change f current-target

                    } <<< (if type == \checkbox then {checked: value == \true} else {value})

            {ui-value-from-state, state-from-ui-value, parameters-from-ui-value}? = control

            {} <<< control <<<

                # ui-value-from-state :: State -> UIValue
                ui-value-from-state: (state) ~> 
                    result = (ui-value-from-state ? (state) ~> state[name]) state
                    return switch
                        | typeof result == \object => (if is-empty-object result then undefined else result)
                        | _ => result
                    
                # state-from-ui-value :: UIValue -> State
                state-from-ui-value: state-from-ui-value ? (ui-value) ~> "#{name}" : ui-value
                
                # parameters-from-ui-value :: UIValue -> Parameters
                parameters-from-ui-value: parameters-from-ui-value ? (ui-value) ~> "#{name}" : parser ui-value

                # render :: UIValue -> (UIValue -> ()) -> ReactElement
                render: render
        
        # extract (parameters :: Map String, a) from controls
        parameters = {} <<< @props.parameters <<< 
            controls 
                |> map ({name, default-value, ui-value-from-state, parameters-from-ui-value, client-side}?) ~> 
                    (parameters-from-ui-value (ui-value-from-state @props.state) ? default-value) |> Obj.map ->
                        value: it
                        client-side: client-side
                |> fold do 
                    (memo, obj) ~> {} <<< memo <<< obj
                    {}

        change = !(parameters `is-equal-to-object` @state.parameters)

        {controls, parameters, change}

    # execute :: () -> ()
    execute: !->
        <~ do ~> (callback) ~>
            current-parameters = @get-computed-state!.parameters
            
            # fake a change to rexecute the query
            if @state.parameters `is-equal-to-object` current-parameters
                @set-state do 
                    refresh-count: @state.refresh-count + 1
                    callback

            else
                @set-state do 
                    parameters: current-parameters
                    callback

        @props.on-execute do 
            @state.parameters |> Obj.map (.value)

    # reset :: () -> ()
    reset: !->
        @props.on-change {}
        @props.on-reset!

    # component-will-mount :: () -> ()
    component-will-mount: !-> 
        @execute!
        @unbind-execute-hotkeys = on-hotkeys ['command + enter', 'ctrl + enter'], ~> @execute!
        @unbind-reset-hotkeys = on-hotkeys ['alt + r', 'option + r'], ~> @reset!

    # component-will-unmount :: () -> ()
    component-will-unmount: !->
        @unbind-execute-hotkeys!
        @unbind-reset-hotkeys!

