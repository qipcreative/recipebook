class App
    # Application Constructor
    initialize: ->
        this.bindEvents()

    # Bind Event Listeners
    #
    # Bind any events that are required on startup. Common events are:
    # 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: ->

        if (navigator.userAgent.match(/(iPhone|iPod|iPad|Android|BlackBerry)/))
            document.addEventListener("deviceready", @.onDeviceReady, false)
        else
            @.onDeviceReady()

    onDeviceReady: ->
        #document.addEventListener "touchmove", (e) ->
            #e.preventDefault()
        #window.iosScroller = new iScroll('full-page')
        new FastClick(document.body)
        window.allRecipes = new Recipes
        scroll = new iScroll 'full-page', {
            vScrollbar: false
            momentum: false
            bounce: false
        }
        setTimeout ->
            navigator.splashscreen.hide()
        , 2000
        @panel = new BottomPanel
        $('#app').append @panel.el
        window.allRecipes.fetch( {
            success: ->
                window.recipes = new Recipes(window.allRecipes.models)
                @list = new BottomPanelList(window.recipes)
                
            error: ->
                #alert("ERROR!")
            })
        

class Recipe extends Backbone.Model


class Recipes extends Backbone.Collection

    model: Recipe

    initialize: ->
        @storage = new Offline.Storage('recipes', this)

    url: ->
        'http://limitless-dawn-7700.herokuapp.com/recipes.json'

    search: (string) ->
        collection = @.filter (recipe) =>
            search = string.toLowerCase()
            name = recipe.get("name").toLowerCase()
            name.indexOf(search) != -1
        collection

class BottomPanel extends Backbone.View

    id: "bottom-panel"

    initialize: ->
        @.render()

    render: (collection) ->
        template = Handlebars.compile($("#bottom-panel-template").html());
        @$el.html(template())
        @

    events: {
        "click .expand" :   "expand"
        "keyup input"   :   "search"
        "click .left"   :   "left"
        "click .right"  :   "right"
        "touchstart div":   "tapped"
        "touchend div"  :   "untapped"
    }

    tapped: (e) ->
        $(e.target).addClass "tapped"

    untapped: (e) ->
        $(e.target).removeClass "tapped"

    expand: ->
        @$el.toggleClass "active"

    search: ->
        val = @.$('input').val()
        window.searchRecipes = new Recipes(window.recipes.search(val))
        list = new BottomPanelList({ collection: window.searchRecipes })

    left: ->
        @$el.removeClass "active"
        if typeof window.currentRecipe == 'undefined'
            recipe = _.last window.allRecipes.models
        else 
            if window.recipes.at(window.currentRecipe - 1)
                recipe = window.recipes.at(window.currentRecipe - 1)
            else 
                recipe = _.last window.allRecipes.models

        new FullRecipeView({ model: recipe }).render()

    right: ->
        @$el.removeClass "active"
        if typeof window.currentRecipe == 'undefined'
            recipe = _.first window.allRecipes.models
        else 
            recipe = window.recipes.at(window.currentRecipe + 1)

        new FullRecipeView({ model: recipe }).render()


class BottomPanelList extends Backbone.View

    el: '#recipe-list'

    initialize: ->
        @.render()
        scroll = new iScroll 'recipe-list-wrapper', {
            vScroll: false
            hScroll: true
            snap: '.recipe-pane'
            snapThreshold: 100
            momentum: false
            hScrollbar: false
            onScrollEnd: ->
                index = @.x / $('.recipe-pane').width()
                $('.progress-circle').removeClass('active').eq(-index).addClass('active')
        }

    render: ->
        @$el.html('')
        if $(window).width() < 400 then number = 6 else number = 8
        console.log @collection
        if @collection
            recipes = @collection
        else 
            recipes = window.recipes
        recipesClone = new Recipes(recipes.models)
        while recipesClone.length > 0
            pane = new RecipePaneView({ collection: recipesClone.first(number) })
            $('#recipe-list').append(pane.render())
            recipesClone = new Recipes(recipesClone.rest(number))
        $('#recipe-list').width($('.recipe-pane').width() * $('.recipe-pane').length)
        $('#recipe-panel-progress').html('')
        _.each $('.recipe-pane'), (pane) ->
            $('#recipe-panel-progress').append $('<div/>').addClass('progress-circle')
        $('#recipe-panel-progress .progress-circle').first().addClass('active')
        @

class RecipePaneView extends Backbone.View

    tagName:   'ul'
    className: 'recipe-pane'

    render: ->
        #console.log @collection
        _.each @collection, (model) =>
            @$el.append(new RecipeView({ model: model }).render())
        @$el

class RecipeView extends Backbone.View

    tagName: 'li'

    render: ->
        template = Handlebars.compile($("#recipe-template").html());
        @$el.html(template(@.model.toJSON()))
        @$el

    events:
        "click" : "show"
        "touchstart" : "tapped"
        "touchend"   : "untapped"

    tapped: ->
        @$el.addClass "tapped"

    untapped: ->
        @$el.removeClass "tapped"

    show: ->
        $('#bottom-panel').removeClass('active')
        if typeof window.mainScroll == 'undefined'
            $('#full-page').html('<div class="recipe-wrapper"/>')
            new FullRecipeCollectionView().render(window.recipes.indexOf @.model)
        else 
            window.mainScroll.scrollToElement($('.recipe').get(window.recipes.indexOf @.model), 0)
        $(window.scrollers).each ->
            @.scrollTo(0,0)

class FullRecipeCollectionView extends Backbone.View

    el: '.recipe-wrapper'

    render: (index) ->
        template = Handlebars.compile($("#full-recipe-template").html());
        window.scrollers = new Array
        if $(window).width() < 400 then threshold = 100 else threshold = 200
        window.recipes.each (model) =>
            view = new FullRecipeView({model: model})
            el = view.render()
            @$el.append(el)
            @scroll = new iScroll el, {
                vScroll: true
                vScrollbar: false
                hScroll: false
                hScrollbar: false
                lockDirection: true
            }
            view.scroll = @scroll
            window.scrollers.push(@scroll)

        window.mainScroll = new iScroll 'full-page', {
            vScrollbar: false
            hScroll: true
            vScroll: false
            hScrollbar: false
            snap: '.recipe'
            snapThreshold: threshold
            momentum: false
            lockDirection: true
            onScrollEnd: ->
                if @.absDistX > threshold 
                    $(window.scrollers).each ->
                        @.scrollTo(0,0)
        }

        window.mainScroll.scrollToElement($('.recipe').get(index), 0)



class FullRecipeView extends Backbone.View

    className: 'recipe'

    render: ->
        template = Handlebars.compile($("#full-recipe-template").html());
        #window.currentRecipe = window.recipes.indexOf @.model
        #window.nextRecipe = window.recipes.at(window.currentRecipe + 1)
        @$el.html(template(@.model.toJSON()))

            

        @el
        #@$el.scrollTop(0)

    events:
        "click .down" : "down"
        "touchstart .down" : "tapped"
        "touchend .down"   : "untapped"
        "click"            : "hidepanel"

    hidepanel: ->
        if $('#bottom-panel').hasClass('active')
            $('#bottom-panel').removeClass('active')

    tapped: ->
        @$('.down').addClass "tapped"

    untapped: ->
        @$('.down').removeClass "tapped"

    down: ->
        if $(window).width() < 400 then down = -420 else down = -880
        @scroll.scrollTo(0, down, 500)


window.app = new App
window.app.initialize()

setInterval()

Handlebars.registerHelper 'nl2br', (text) ->
    nl2br = (text + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + '<br>' + '$2')
    new Handlebars.SafeString(nl2br)
