module Main exposing (Model, Msg, init, subscriptions, update, view)

import Browser
import Browser.Navigation as Nav
import Html.Styled as Html exposing (..)
import Page.Dashboard as Dashboard
import Page.Login as Login
import Page.Portfolio as Portfolio
import Route
import Session
import Shell
import Url
import Url.Parser
import User


main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = SetRoute
        }


type Page
    = Loading
    | Login Login.Model
    | Dashboard Dashboard.Model
    | Portfolio Portfolio.Model


type alias Model =
    { page : Page
    , session : Maybe String
    , navKey : Nav.Key
    , navOpen : Bool
    , user : Maybe User.User
    }


type Msg
    = SetRoute Url.Url
    | LinkClicked Browser.UrlRequest
    | SessionChanged (Maybe String)
    | ToggleNav
    | LoginMsg Login.Msg
    | DashboardMsg Dashboard.Msg
    | PortfolioMsg Portfolio.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case ( message, model.page ) of
        ( SetRoute url, _ ) ->
            setRoute url model

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( SessionChanged session, _ ) ->
            let
                newModel =
                    { model | session = session }
            in
            case ( session, model.page ) of
                ( Nothing, Login _ ) ->
                    ( newModel, Cmd.none )

                ( Nothing, _ ) ->
                    ( newModel, Route.redirect model.navKey Route.Login )

                ( Just _, Login _ ) ->
                    ( newModel, Route.redirect model.navKey Route.Dashboard )

                ( Just _, _ ) ->
                    ( newModel, Cmd.none )

        ( ToggleNav, _ ) ->
            ( { model | navOpen = not model.navOpen }, Cmd.none )

        ( LoginMsg msg, Login login ) ->
            let
                ( newLoginModel, cmd ) =
                    Login.update msg login
            in
            ( { model | page = Login newLoginModel }, Cmd.map LoginMsg cmd )

        ( DashboardMsg msg, Dashboard dashboard ) ->
            let
                ( newDashboardModel, cmd, outMsg ) =
                    Dashboard.update msg dashboard

                newModel =
                    case outMsg of
                        Dashboard.NoMsg ->
                            model

                        Dashboard.SetUser user ->
                            { model | user = Just user }
            in
            ( { newModel | page = Dashboard newDashboardModel }, Cmd.map DashboardMsg cmd )

        ( PortfolioMsg msg, Portfolio portfolio ) ->
            let
                ( newPortfolioModel, cmd ) =
                    Portfolio.update msg portfolio
            in
            ( { model | page = Portfolio newPortfolioModel }, Cmd.map PortfolioMsg cmd )

        ( _, _ ) ->
            -- Ignore messages arriving for the wrong page
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    case model.page of
        Loading ->
            Shell.view model.navOpen ToggleNav never <|
                { title = ""
                , showHeader = True
                , header = Nothing
                , main = text "Loading…"
                }

        Login loginModel ->
            Shell.view model.navOpen ToggleNav LoginMsg <|
                Login.view loginModel

        Dashboard dashboardModel ->
            Shell.view model.navOpen ToggleNav DashboardMsg <|
                Dashboard.view dashboardModel

        Portfolio portfolioModel ->
            Shell.view model.navOpen ToggleNav PortfolioMsg <|
                Portfolio.view portfolioModel


subscriptions : Model -> Sub Msg
subscriptions model =
    Session.onSessionChange SessionChanged


init : Maybe String -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init session url navKey =
    setRoute url
        { page = Loading
        , session = session
        , navKey = navKey
        , navOpen = False
        , user = Nothing
        }


setRoute : Url.Url -> Model -> ( Model, Cmd Msg )
setRoute url model =
    let
        route =
            Url.Parser.parse Route.route url
                |> Maybe.withDefault Route.Dashboard
    in
    case ( model.session, route ) of
        ( Nothing, Route.Login ) ->
            ( { model | page = Login (Login.init model.navKey) }, Cmd.none )

        ( Just session, Route.Login ) ->
            ( model, Route.redirect model.navKey Route.Dashboard )

        ( Nothing, _ ) ->
            ( model, Route.redirect model.navKey Route.Login )

        ( Just session, Route.Dashboard ) ->
            let
                ( newModel, cmd ) =
                    Dashboard.init session
            in
            ( { model | page = Dashboard newModel }, Cmd.map DashboardMsg cmd )

        ( Just session, Route.Portfolio ) ->
            let
                ( newModel, cmd ) =
                    Portfolio.init session
            in
            ( { model | page = Portfolio newModel }, Cmd.map PortfolioMsg cmd )
            