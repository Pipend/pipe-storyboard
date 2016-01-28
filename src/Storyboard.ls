require! \keyboardjs
{filter, find, fold, id, is-it-NaN, map, Obj, obj-to-pairs, pairs-to-obj} = require \prelude-ls
{is-equal-to-object} = require \prelude-extension
{DOM:{div, input, label}, Children, clone-element, create-class, create-factory} = require \react
Form = create-factory require \./Form
require! \react-selectize
SimpleSelect = create-factory react-selectize.SimpleSelect

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
        cache: true
        '''
        Control :: {
            name :: String, 
            type :: String, 
            label :: String,
            placeholder :: String, 
            options: [String], 
            tether :: Boolean,
            default-value :: a, 
            ui-value-from-state :: State -> UIValue, 
            state-from-ui-value :: UIValue -> State, 
            parameters-from-ui-value :: UIValue -> Parameters, where Parameters :: Map Name, Value
            render? :: UIValue -> (UIValue -> Void) -> ReactElement
        }
        '''
        controls: [] # [Control]
        parameters: {}
        state: {} # state :: State
        url: undefined # String
        
        # on-change :: State -> Void
        on-change: (state) !-> 

    # render :: a -> ReactElement
    render: ->
        {change, controls, parameters} = @get-computed-state!

        div do 
            class-name: \storyboard

            # FORM
            div do 
                class-name: \form, 

                controls |> map (control) ~>
                    {name, default-value, placeholder, render, ui-value-from-state, state-from-ui-value}? = control
                    
                    value = ui-value-from-state @props.state

                    # ROW
                    div do 
                        key: name

                        # LABEL
                        if !!control?.label
                            label null, control.label

                        # INPUT FIELD
                        render do 
                            value ? default-value
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
                            parameters: @state.parameters
                            url: child.props?.url ? @props.url

    # get-initial-state :: () -> UIState
    get-initial-state: -> parameters: {}

    # get-computed-state :: () -> ComputedState :: {controls :: [Control], parameters :: Parameters}
    get-computed-state: ->

        # update controls with defaults for the (ui-value-from-state, state-from-ui-value & parameters-from-ui-value) functions
        controls = @props.controls |> map (control) ~>
            {name, placeholder, tether, type, ui-value-from-state, state-from-ui-value, parameters-from-ui-value}? = control

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

            # render :: UIValue -> (UIValue -> Void) -> ReactElement
            render = control.render ? (value, on-change) ->
                switch type
                | \select =>
                    SimpleSelect do 
                        key: name
                        tether: tether
                        placeholder: placeholder
                        value: 
                            | typeof value == \undefined => undefined
                            | _ => 
                                label: value
                                value: value
                        options: options |> map ~> label: it, value: it
                        on-value-change: ({value}, callback) ~> 
                            on-change value
                            callback!

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

                    } <<< (if type == \checkbox then {checked: value} else {value})

            {} <<< control <<<

                # ui-value-from-state :: State -> UIValue
                ui-value-from-state: ui-value-from-state ? (state) ~> parser state[name]
                    
                # state-from-ui-value :: UIValue -> State
                state-from-ui-value: state-from-ui-value ? (ui-value) ~> "#{name}" : parser ui-value
                
                # parameters-from-ui-value :: UIValue -> Parameters
                parameters-from-ui-value: parameters-from-ui-value ? (ui-value) ~> "#{name}" : ui-value

                # render :: UIValue -> (UIValue -> Void) -> ReactElement
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
        @set-state parameters: @get-computed-state!.parameters

    # reset :: () -> ()
    reset: !->
        @props.on-change {}

    # component-will-mount :: () -> ()
    component-will-mount: !-> 
        @execute!
        @unbind-execute-hotkeys = on-hotkeys ['command + enter', 'control + enter'], ~> @execute!
        @unbind-reset-hotkeys = on-hotkeys ['alt + r', 'option + r'], ~> @reset!

    component-will-unmount: !->
        @unbind-execute-hotkeys!
        @unbind-reset-hotkeys!

