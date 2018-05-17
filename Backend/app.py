#!flask/bin/python
from flask import Flask, jsonify
from flask import request
import csv
import sys
import json
import operator
import string

app = Flask(__name__)

def addDescriptions(flights, keywords):
    result = []
    reader = csv.reader(open("Short-Descriptions.csv"), delimiter=',')
    for row in reader:
        keys = row
        keys = [key.lower() for key in keys]
        break
    for row in reader:
        descriptions = row
    for flight in flights:
        if len(flight["reasons"]) == 0:
            for key in keywords:
                try:
                    index = keys.index(key)
                    reader2 = csv.reader(open("YHacks-Dataset.csv"), delimiter=',')
                    for city in reader2:
                        if city[0] == flight["destCity"]:
                            if city[index] != "Yes":
                                continue
                    description = descriptions[index]
                    newdescription = string.replace(description, 'KEYWORD', flight["destCity"])
                    result.append(newdescription)
                except ValueError:
                    continue
        else:
            continue
        flight["reasons"] = result
        result = []
    return flights

def cleanedKeywords(keywords):
    for key in keywords:
        keywords = [key.lower() for key in keywords]
        
    removeKeys = []
    reader = csv.reader(open('YHacks-Dataset.csv'), delimiter=',')
    for row in reader:
        keys = row
        keys = [key.lower() for key in keys]
        break
    for key in keywords:
        if key not in keys:
            removeKeys.append(key)

    for key in removeKeys:
        keywords.remove(key)

    return keywords

def topFlights(flights):
    sorted_flights = sorted(flights, key=lambda k: k['fare'])
    if len(sorted_flights) > 4:
        size = len(sorted_flights) / 2
        result = sorted_flights[:2] + sorted_flights[size:size+1] + sorted_flights[-1:]
        return result
    return sorted_flights

def addKeywordReasons(flights, keywords):
    reader = csv.reader(open('YHacks-Dataset.csv'), delimiter=',')
    reader2 = csv.reader(open('Short-Descriptions.csv'), delimiter=',')
    topics = []
    descriptions = []
    for row2 in reader2:
        topics = row2
    for row2 in reader2:
        descriptions = row2
    for row in reader:
        keys = row
        keys = [key.lower() for key in keys]
        break
    for row in reader:
        for flight in flights:
            if row[1] == flight['destAirport']:
                reason = []
                flight["destCity"] = row[0]
                flight["destCountry"] = row[2]
                for key in keywords:
                    index = keys.index(key)
                    if row[index] != "Yes":
                        reason.append(row[index])
                    elif row[index] == "Yes":
                        try:
                            index2 = topics.index(key)
                            reason.append(descriptions[index2])
                        except:
                            pass
                flight["reasons"] = ",".join(str(x) for x in reason)

    return flights

def getLocationFromAirport(airports):
    dests = []
    reader = csv.reader(open('airport.csv'), delimiter=',')
    for airport in reader:
        for port in airports:
            if airport[0] == port:
                dests.append((float(airport[2]), float(airport[1])))

    return dests

def getAirport(long, lat):
    distance = sys.maxint
    reader = csv.reader(open('airport.csv'), delimiter=',')
    for row in reader:
        if ((long-float(row[2]))**2+(lat-float(row[1]))**2)**0.5 < distance:
            distance = ((long-float(row[2]))**2+(lat-float(row[1]))**2)**0.5
            destAirport = row[0]
    return destAirport

def bestFlightsFrom(origLong, origLat, dests, departureDate):
    origAirport = getAirport(origLong, origLat)
    flights = []
    for x in xrange(len(dests)):
        flightFound = False
        flight = {}
        destAirport = getAirport(dests[x][0], dests[x][1])
        flight["departureDate"] = departureDate
        flight["origAirport"] = origAirport
        flight["destAirport"] = destAirport
        flight["fare"] = sys.maxint
        
        reader = csv.reader(open('LowestFares.csv'), delimiter=',')
        for trip in reader:
            if departureDate in trip[2]:
                if trip[0] == origAirport and trip[1] == destAirport:
                    print(destAirport)
                    if float(trip[5]) < float(flight["fare"]):
                        flight["fare"] = '%.2f' % float(trip[5])
                        flightFound = True
        if flightFound:
            flights.append(flight)
    return flights


def getDestination(origLong, origLat, keywords):
    amount = len(keywords)
    airports = []
    reader = csv.reader(open('YHacks-Dataset.csv'), delimiter=',')
    first =True
    keys = []
    for airport in reader:
        if first:
            keys = airport
            keys = [key.lower() for key in keys]
            first = False
        elif airport[0] == '':
             break
        else:
            correct = 0
            exitStatus = False
            for x in xrange(amount):
                index = keys.index(keywords[x].lower())
                if airport[index]  != 'NULL':
                    correct+=1
            if correct+1 >= amount:
                if len(airport) > 1:
                    airports.append(airport[1])

    return getLocationFromAirport(airports)



@app.route('/getFlights', methods=['POST'])
def get_flights():
    origLong = float(request.json["origLong"])
    origLat = float(request.json["origLat"])
    departureDate = request.json["departureDate"]
    destLong = float(request.json["destLong"])
    destLat = float(request.json["destLat"])
    if destLong != -1:
        dests = [(destLong,destLat)]
        print(dests)
        flights = bestFlightsFrom(origLong, origLat, dests, departureDate)
        flights = addKeywordReasons(flights, [])

    else:
        keywords = request.json["keywords"]
        print(keywords)
        keywords = cleanedKeywords(eval(keywords))
        dests = getDestination(origLong, origLat, keywords)
        print("got destinations")
        if dests == None:
            return jsonify({"status" : "OK", "flights" : [{}], "amountOfFlights": 0})
        flights = bestFlightsFrom(origLong, origLat, dests, departureDate)
        print("best flights retrieved")
        flights = addKeywordReasons(flights, keywords)
        #flights = addDescriptions(flights, keywords)
        print("adding metadata")
        
    flights = topFlights(flights)
    return jsonify({"data" : {"status" : "OK", "flights" : flights, "amountOfFlights" : len(flights)}})


if __name__ == '__main__':
    app.run(port=8080,debug=True)
