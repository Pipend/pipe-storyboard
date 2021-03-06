require! \clipboard
{is-equal-to-object} = require \prelude-extension
require! \pipe-web-client
prefixer = new (require \inline-style-prefixer)!
{all, filter, id, map, Obj, obj-to-pairs, pairs-to-obj, reject} = require \prelude-ls
require! \querystring
{DOM:{a, div}, create-class, create-factory} = require \react
{find-DOM-node} = require \react-dom

DefaultLinks = create-factory create-class do 

    # get-default-props :: () -> Props
    get-default-props: ->
        # query-id :: String
        # branch-id :: String
        url: ""
        cache: false
        parameters: {}

    # render :: () -> ReactElement
    render: ->
        {query-id, branch-id, parameters, url, cache}? = @props
        segment = if query-id then "queries/#{query-id}" else "branches/#{branch-id}"
        share-url = "#{url}/apis/#{segment}/execute/#{@props.cache}/presentation?"

        div do 
            class-name: \links

            a do 
                href: "#{url}/#{segment}"
                target: \_blank
                \Edit

            a do
                href: "#{share-url}#{decode-URI-component querystring.stringify parameters}"
                target: \_blank
                \Share

            a do 
                ref: \parameters
                \data-clipboard-text : (JSON.stringify parameters, null, 4)
                \Parameters
                
            a do 
                href: "#{url}/ops"
                target: \_blank
                'Task Manager'

    # component-did-mount :: () -> Void
    component-did-mount: !->
        if !!@refs.parameters
            new clipboard find-DOM-node @refs.parameters


module.exports = create-class do 

    display-name: \Story

    # get-default-props :: a -> Props
    get-default-props: ->
        branch-id: "" 
        cache: undefined # Boolean
        class-name: ""
        extras: {}
        parameters: {} # Map ParameterName, {value :: a, client-side :: Boolean}
        prefix-styles: true
        query-id: ""

        # render-links :: -> ReactElement
        render-links: DefaultLinks

        show-links: true
        show-title: true
        style: {}
        title: undefined
        url: undefined # String

    # render :: a -> ReactElement
    render: ->
        {branch-id, cache, class-name, query-id, show-links, show-title, url}? = @props
        expand = !show-title and !show-links
        parameters = @finalize @props.parameters 
        

        div do 
            class-name: "story #{class-name} #{if @state.loading then 'loading' else ''} #{if expand then 'expand' else ''}"
            style: (if @props.prefix-styles then prefixer.prefix @props.style else @props.style)

            if !expand
                div do 
                    class-name: \header

                    # TITLE
                    if @props.show-title
                        div do 
                            class-name: \title
                            @props.title ? @state.document.query-title

                    # LINKS
                    if @props.show-links
                        @props.render-links {branch-id, cache, query-id, url, parameters}

            # PRESENTATION
            div do 
                class-name: \presentation-container
                ref: \presentation-container

    # get-initial-state :: a -> UIState
    get-initial-state: ->
        loading: false
        document : {} # {query-title :: String, ...}
        # execute :: Parameters -> Boolean -> p result
        # presentation-function :: Parameters -> DOMElement -> result
        # result :: object

    # component-will-mount :: () -> Void        
    component-will-mount: !->
        {compile-query, compile-latest-query} = pipe-web-client end-point: @props.url

        # load & compile the query from pipe
        {document, execute, transformation-function, presentation-function} <~ (do ~>
            if !!@props.query-id 
                compile-query @props.query-id 
            else 
                compile-latest-query @props.branch-id) .then _

        # update the state with:
        #  execute :: Parameters -> p result
        #  tranformation-function :: result -> Parameters -> result
        #  presentation-function :: DOMElement -> result -> Parameters -> DOM()
        <~ @set-state {document, execute, transformation-function, presentation-function}
        @refresh @props.cache
    
    # public method to re-execute the query
    # refresh :: Boolean -> ()
    refresh: (cache) ->
        <~ @set-state loading: true

        finalized-parameters = @finalize @props.parameters 
 
        # use parameters to execute the query and update the state with the result
        result <~ @state.execute cache, finalized-parameters .then _
        <~ @set-state {result, loading: false}
        
        {transformation-function, presentation-function} = @state

        # present the result
        presentation-function do 
            find-DOM-node @refs[\presentation-container]
            transformation-function result, finalized-parameters
            finalized-parameters

    # Parameters :: {name: {value :: a, client-side :: Boolean}, ...}
    # Parameters' :: {name: value :: a, ...}
    # finalize :: Parameters -> Parameters'
    finalize: (parameters) -> 
        {} <<< (parameters |> Obj.map (.value)) <<< @props.extras

    # component-will-receive-props :: Props -> Void    
    component-will-receive-props: (next-props) !->
        
        {execute, transformation-function, presentation-function}? = @state

        if !!execute

            # change :: [[name, {value, client-side}]]
            change = next-props.parameters
                |> obj-to-pairs
                |> reject ~> it.1?.value `is-equal-to-object` @props.parameters?[it.0]?.value
                
            if change.length > 0
                client-side = change |> all -> !!it.1?.client-side
                view = find-DOM-node @refs[\presentation-container]
                finalized-parameters = @finalize next-props.parameters

                if client-side

                    # if its a client side change only, then simply transform & present the result
                    # no need to execute the query on the server
                    presentation-function do 
                        view
                        transformation-function @state.result, finalized-parameters
                        finalized-parameters

                else
                    # show preloader
                    <~ @set-state loading: true

                    # execute the query on the server
                    result <~ execute @props.cache, finalized-parameters .then _

                    # hide the preloader
                    <~ @set-state {result, loading: false}

                    # transform and present the result
                    presentation-function do 
                        view
                        transformation-function result, finalized-parameters
                        finalized-parameters