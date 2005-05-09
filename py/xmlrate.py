#!/usr/bin/env python

import sys
import glicko2
import xml.dom.minidom

# globals
gPlayers = dict()
gTeams   = dict()


def getText(nodelist):
    rc = ""
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc = rc + node.data
    return rc


def parsePlayers (docroot):

    # get players
    playerelements = docroot.getElementsByTagName("player")

    # parse each player
    for player in playerelements:

        # get the name
        namenode = player.getElementsByTagName("name")
        assert namenode
        name = getText(namenode[0].childNodes)

        # setup default rating data
        g2 = glicko2.Glicko2()

        # look for rating
        ratingnode = player.getElementsByTagName("rating")
        if ratingnode:
            g2.SetRating( float(getText(ratingnode[0].childNodes)) )

        # look for deviation
        deviationnode = player.getElementsByTagName("deviation")
        if deviationnode:
            g2.SetDeviation( float(getText(deviationnode[0].childNodes)) )

        # look for volatility
        volatilitynode = player.getElementsByTagName("volatility")
        if volatilitynode:
            g2.SetVolatility( float(getText(volatilitynode[0].childNodes)) )

        # add to dictionary
        gPlayers[name] = g2


def parseTeams (docroot):

    # get teams
    teamelements = docroot.getElementsByTagName("team")

    # parse each team
    for team in teamelements:

        # get the name
        namenode = team.getElementsByTagName("name")
        assert namenode
        name = getText(namenode[0].childNodes)

        # add name to our dictionary
        gTeams[name] = []

        # look for members, add to dictionary
        membernode = team.getElementsByTagName("member")
        assert membernode # makes certain team is not empty
        for member in membernode:
            gTeams[name].append( getText(member.childNodes) )


def outputPlayers():
    sorted = [(v, k) for k, v in gPlayers.items()]
    sorted.sort()
    sorted.reverse()             # so largest is first
    sorted = [(k, v) for v, k in sorted]
    i = 0
    for k,v in sorted:
        i += 1
        print "%3d%30s: %6.1f   +/- %5.1f   %0.05f" % \
            ( i, k, v.GetRating(), v.GetDeviation(), v.GetVolatility() )




def handlePeriods (docroot):

    # our period count
    periodcount = 0

    # get all periods
    periodelements = docroot.getElementsByTagName("period")

    # handle each period
    for period in periodelements:

        # track period id
        periodcount += 1
        print
        print "after rating period",periodcount

				# deal with either a race or a game node
        for node in period.childNodes:
            if node.nodeType == node.ELEMENT_NODE:
								if node.tagName == "race":
										handleRace(node)
								elif node.tagName == "game":
										handleGame(node)

        # all games entered for this period, now update all players ratings
        for k,v in gPlayers.items():
            v.Update()

        # sort players for output
        outputPlayers()


def handleRace (race):

		# get competitors
    competitornodes = race.getElementsByTagName("competitor")

    # a list of our racers
    racelist = []

    for competitor in competitornodes:

				# get name from XML
        competitorname = getText(competitor.childNodes)

				# look name up in our team list
        if gTeams.has_key(competitorname):
            competitornames = gTeams[competitorname]
        else:
            competitornames = [competitorname]

        # make all of these competitors losers to everyone already in the list
        for plist in racelist:
            for pl in plist:
                for co in competitornames:
                    gPlayers[pl].AddWin(gPlayers[co])
                    gPlayers[co].AddLoss(gPlayers[pl])

        # now let's add this list to our race list
        racelist.append( competitornames )



def handleGame (game):

    # get home
    homenode = game.getElementsByTagName("home")
    assert homenode
    home = getText(homenode[0].childNodes)

    # get away
    awaynode = game.getElementsByTagName("away")
    assert awaynode
    away = getText(awaynode[0].childNodes)

    # get result
    resultnode = game.getElementsByTagName("result")
    assert resultnode
    result = getText(resultnode[0].childNodes)
    assert result == "win" or result == "loss" or result == "draw"

    # see if home is a team
    if gTeams.has_key(home):
        homeplayernames = gTeams[home]
    else:
        homeplayernames = [home]

    # see if away is a team
    if gTeams.has_key(away):
        awayplayernames = gTeams[away]
    else:
        awayplayernames = [away]

    # determine each team's result
    if result == "win":
        homeresult = glicko2.Glicko2.WIN
        awayresult = glicko2.Glicko2.LOSS
    elif result == "loss":
        homeresult = glicko2.Glicko2.LOSS
        awayresult = glicko2.Glicko2.WIN
    elif result == "draw":
        homeresult = glicko2.Glicko2.DRAW
        awayresult = glicko2.Glicko2.DRAW

    # now let's add all the results to the Glicko2 objects
    for hname in homeplayernames:
        for aname in awayplayernames:
            gPlayers[hname].AddResult( gPlayers[aname], homeresult )
    for aname in awayplayernames:
        for hname in homeplayernames:
            gPlayers[aname].AddResult( gPlayers[hname], awayresult )






def main ():

    # parse input document
    docroot = xml.dom.minidom.parse(sys.argv[1])

    # build player & team list
    parsePlayers(docroot)
    parseTeams(docroot)

		# show initial ratings
    print "initial ratings"
    outputPlayers()

    # process all the periods
    handlePeriods(docroot)


if __name__ == '__main__':
    main()

