import $ from 'jquery'
import angular from 'angular'
import utils from "utils"

import PKCE from 'js-pkce';
# import '../needsharebutton.min.js'
# import 'angular-ui-bootstrap'

import('bootstrap/dist/css/bootstrap.min.css')
import('../vendor/font-awesome.css')
import('./player.less') 

import 'bootoast/dist/bootoast.min.css'
# import bootoast from 'bootoast/dist/bootoast.min.js'

import spotifyUri from 'spotify-uri'

spotifyClientId = '71996e28dc6f40cc89f05bd0b030708e'
# some ui need bootstrap, like dropdown.
musicPlayer = angular.module('musicPlayer', []).config(($sceProvider)->
    $sceProvider.enabled(false);
)

musicPlayer.controller 'musicPlayerCtrl', ['$scope', '$sce', ($scope, $sce) ->
    console.log "[musicPlayerCtrl] init"

    $scope.playing = false
    $scope.canSeekNext = false 
    $scope.canSeekPrev = false 
    $scope.canPause = false 
    $scope.albumImage = null
    $scope.artistName = ''

    getState = () ->
        res = await utils.send 'spotify current state'
        updateState(res) if res 

        chrome.runtime.onMessage?.addListener (request, sender, sendResponse)->
            if request.type == 'spotify state changed'
                updateState(request.state) if request.state 
            if request.type == 'track saved'
                checkTrackSaved()

    checkTrackSaved = () ->
        if $scope.spotifyState.current_track?.id 
            $scope.spotifyState.current_track.saved = await utils.send 'checkUserSavedTrack', { trackId: $scope.spotifyState.current_track.id }

            # console.log "check saved: ", $scope.spotifyState.current_track.saved
            $scope.savingTrack = false
            $scope.$apply()

    updateState = (state) ->
        $scope.spotifyState = state 
        # console.log "Spotify state: ", state 

        $scope.isSpotifyReady = state.ready

        $scope.canPause = false 
        $scope.canSeekNext = false 
        $scope.canSeekPrev = false 
        $scope.playing = false 

        $scope.albumImage = null 
        $scope.artistName = ''

        if state.disallows
            $scope.canPause = !state.disallows.pausing
            $scope.canSeekNext = !state.disallows.peeking_next
            $scope.canSeekPrev = !state.disallows.peeking_prev  

        if state.current_track?.album?.images?.length
            $scope.albumImage = state.current_track.album.images.find((n) -> n.width > 200) or \
                state.current_track.album.images[0]
        if state.current_track?.artists?.length 
            $scope.artistName = state.current_track.artists.map((n) -> n.name).join(', ')

        checkTrackSaved(state.current_track)
        
        $scope.playing = !state.paused and state.current_track
        $scope.$apply()

    $scope.toggleAction = (action) -> 
        if not $scope.isSpotifyReady
            window.open('/authorized.html', '_blank')
            
        else if $scope.spotifyState?.current_track
            utils.send 'spotify action', { action }
        else 
            window.open('https://open.spotify.com/', '_blank')
    
    $scope.toggleSavedTrack = () ->
        if $scope.spotifyState.current_track and !$scope.savingTrack
            $scope.savingTrack = true

            if $scope.spotifyState.current_track.saved 
                res = await utils.send 'removeUserSavedTrack', { trackId: $scope.spotifyState.current_track.id }
                # console.log "remove saved: ", res
            else 
                res = await utils.send 'saveUserTrack', { trackId: $scope.spotifyState.current_track.id }
                # console.log "save: ", res 

            checkTrackSaved($scope.spotifyState.current_track)
    
    $scope.openTrackLink = () ->
        if $scope.spotifyState?.current_track
            url = spotifyUri.formatOpenURL $scope.spotifyState.current_track.uri
            window.open url, '_blank'
        else 
            $scope.openHelpLink()
    
    $scope.openHelpLink = () ->
        url = 'https://revir.github.io/2021/01/16/Spotify-on-Chrome/'
        window.open url, '_blank'
    $scope.openOptions = () ->
        utils.send 'open options'

    getState()
]