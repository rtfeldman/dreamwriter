module Component.WordGraph where

import Svg exposing (..)
import Svg.Attributes exposing (..)

type alias Entry =
    {
        words : Int,
        day : String
    }

type alias Day =
    {
        amount : Float,
        day: String,
        offset : Int
    }

graphHeight = 18
barWidth = 10
maxDays = 14

bar : Day -> Float -> Svg
bar day offset =
    rect
        [
            x (day.offset * (barWidth + 2)
                |> toString),
            y (toString (if day.amount <= 0 then offset else offset - day.amount)),
            height (toString (abs day.amount)),
            width (toString barWidth)
        ]
        [ Svg.title [] [ text day.day ] ]

graph : Float -> List Day -> Svg
graph offset days =
    let
        graphWidth = (List.length days) * (barWidth + 2)
        axis = line
            [
                x1 "0",
                y1 (toString offset),
                x2 (toString graphWidth),
                y2 (toString offset)
            ]
            []
    in
        svg
            [
                width (toString graphWidth),
                height (toString graphHeight)
            ]
            [
                g [
                    y (toString offset)
                ]
                (axis :: (List.map (\x -> bar x offset) days))
            ]

scale : Int -> Int -> Int -> Float
scale top bot value =
    let
        range = toFloat top - toFloat bot
        ratio = graphHeight / range
    in
        ratio * toFloat value

viewWordGraph : List Entry -> Svg
viewWordGraph list =
    let
        lastTwoWeeks = List.take maxDays list
        max = List.map (\x -> x.words) lastTwoWeeks
            |> List.maximum
            |> Maybe.withDefault graphHeight
        min = List.map (\x -> x.words) lastTwoWeeks
            |> List.minimum
            |> Maybe.withDefault 0
        offset = scale max min (if (abs max) > (abs min) then max else min)
        days = List.map2 (\offset entry ->
            {
                amount = scale max min entry.words,
                day = entry.day,
                offset = offset
            }) [0..maxDays-1] lastTwoWeeks
    in
        graph offset days
