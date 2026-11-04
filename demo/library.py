#!/usr/bin/env python3
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request

DEMO = os.path.dirname(os.path.abspath(__file__))
MUSIC = os.path.join(DEMO, "music")
HOME = os.path.join(DEMO, "cmus-home")
ALBUM_QUERY = {
    "Make It Big": ("Wham! Make It Big", 0),
    "Out of the Blue": ("Electric Light Orchestra Out of the Blue", 0),
    "Nightflight to Venus": ("Boney M. Nightflight to Venus", 0),
    "DiscO-Zone": ("O-Zone DiscO-Zone", 0),
    "The Album": ("Haddaway The Album", 1),
    "Europop": ("Eiffel 65 Europop", 0),
    "Psy 6 (Six Rules), Part 1": ("PSY 6 Rules Part 1", 0),
    "Super Eurobeat Vol. 84": ("Super Eurobeat Vol. 84", 1),
    "Crazy Frog Presents Crazy Hits": ("Crazy Frog Presents Crazy Hits", 0),
}
BEAT = ("0.45*sin(2*PI*55*t)*exp(-7*mod(t,0.5))"
        "+0.22*sin(2*PI*(110+55*floor(mod(t*2,4)))*t)"
        "+0.12*(sin(2*PI*262*t)+sin(2*PI*330*t)+sin(2*PI*392*t))*(0.4+0.6*exp(-3*mod(t,1)))"
        "+0.08*(sin(2*PI*523*t)+sin(2*PI*784*t)+sin(2*PI*1046*t))*(0.5+0.5*sin(2*PI*0.5*t))"
        "+0.05*(sin(2*PI*1568*t)+sin(2*PI*2093*t)+sin(2*PI*3136*t))*exp(-6*mod(t+0.25,0.5))"
        "+0.06*(random(0)-0.5)*exp(-25*mod(t,0.25))")


def itunes(term, entity, pick):
    query = urllib.parse.urlencode({"term": term, "entity": entity, "limit": 5})
    results = json.load(urllib.request.urlopen(f"https://itunes.apple.com/search?{query}", timeout=20))["results"]
    return results[min(pick, len(results) - 1)] if results else None


def cover(title, artist, album):
    term, pick = ALBUM_QUERY.get(album, (f"{artist} {title}", 0))
    hit = itunes(term, "album" if album in ALBUM_QUERY else "song", pick)
    if not hit:
        return None
    return urllib.request.urlopen(hit["artworkUrl100"].replace("100x100bb", "1000x1000bb"), timeout=30).read()


def main():
    tracks = json.load(open(os.path.join(DEMO, "tracks.json")))
    shutil.rmtree(MUSIC, ignore_errors=True)
    shutil.rmtree(HOME, ignore_errors=True)
    os.makedirs(HOME)
    for title, artist, album, year, seconds in tracks:
        folder = os.path.join(MUSIC, artist.replace("/", "-"), album.replace("/", "-"))
        os.makedirs(folder)
        art = cover(title, artist, album)
        if art:
            open(os.path.join(folder, "cover.jpg"), "wb").write(art)
        else:
            print("no cover:", artist, album, file=sys.stderr)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "lavfi", "-i", f"aevalsrc='{BEAT}':s=32000:d={seconds}",
                        "-c:a", "libopus", "-b:a", "32k", "-metadata", f"title={title}", "-metadata", f"artist={artist}",
                        "-metadata", f"album={album}", "-metadata", f"date={year}",
                        os.path.join(folder, title.replace("/", "-") + ".opus")], check=True)
    env = dict(os.environ, CMUS_HOME=HOME, CMUS_SOCKET=os.path.join(HOME, "socket"))
    cmus = subprocess.Popen(["script", "-qfc", "cmus", "/dev/null"], env=env, stdin=subprocess.PIPE,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    remote = ["cmus-remote", "--server", env["CMUS_SOCKET"]]
    for _ in range(100):
        if subprocess.run(remote + ["-Q"], capture_output=True).returncode == 0:
            break
        time.sleep(0.1)
    subprocess.run(remote + ["-l", MUSIC], check=True)
    time.sleep(3)
    subprocess.run(remote + ["-C", "quit"])
    cmus.wait(timeout=20)
    print(f"{len(tracks)} tracks in {MUSIC}, cmus cache in {HOME}")


if __name__ == "__main__":
    main()
