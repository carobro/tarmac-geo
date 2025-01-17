# tarmac-geo – custom vector tiles for bike infrastructure planning based on OpenStreetMap
# (!) This project is in alpha stage (!)

## About

This project will download, filter and process OpenStreetMap (OSM) data in a PostgreSQL/PostGIS Database and make them available as vector tiles with pg_tileserve.

The data we process is selected and optimize to make planning of bicycle infrastructure easier.

## Production

### Server

https://tiles.radverkehrsatlas.de/

### Data update

* Data is updated once a week, every monday ([cron job definition](https://github.com/FixMyBerlin/tarmac-geo/blob/main/.github/workflows/generate-tiles.yml#L3-L6))
* Data can manually updates [via Github Actions ("Run workflow > from Branch: main")](https://github.com/FixMyBerlin/tarmac-geo/actions/workflows/generate-tiles.yml).

### Deployment

1. https://github.com/FixMyBerlin/tarmac-geo/actions run
2. Then our Server IONOS builds the data. This take about 30 Min ATM.
3. Then https://tiles.radverkehrsatlas.de/ shows new data

## 1️⃣ Setup

First create a `.env` file. You can use the `.env.example` file as a template.

```sh
docker compose up
```

This will create the docker container and run all scripts. One this is finished, you can use the pg_tileserve-vector-tile-preview at http://localhost:7800/ to look at the data.

### Using PostgREST

If you want to use the PostgREST service for interacting with the database, you need to configure a role which is allowed to handle requests.

We currently only use anonymous requests. To create the role and assign the correct privileges follow:

1. `CREATE ROLE api_read nologin;`
2. `GRANT USAGE ON SCHEMA PUBLIC to api_read;`
3. `GRANT SELECT ON public.<YOURTABLE> to api_read;`


If you planning using another role than `api_read`, you need to adjust the environment variable `PGRST_DB_ANON_ROLE` in the docker compose file.


> **Note**
> We use a custom build for `postgis` in [db.Dockerfile] to support Apple ARM64

## 💪 Work

You can only rebuild and regenerate the whole system, for now. The workflow is…

1. Edit the files locally

2. Rebuild and restart everything

   ```sh
   docker compose build && docker compose up
   ```

3. Inspect the new results

**TODOs**

- [ ] Allow editing code direclty inside the docker container, so no rebuild is needed; change the re-generation-part
- [ ] Split of the downloading of new data

**Notes**

Hack into the bash

```sh
docker compose exec app bash
```

You can also run the script locally:

1. This requires a new user in postgres which is the same as your current user:
   ```sh
   sudo -u postgres createuser --superuser $USER; sudo -u postgres createdb $USER
   ```
2. Then copy the [configuration file](https://www.postgresql.org/docs/current/libpq-pgservice.html) `./config/pg_service.conf` to `~/.pg_service.conf` and adapt your username and remove the password.

**Build & Run only one container**
Build docker

```sh
docker build -f app.Dockerfile -t tarmac:latest .
```

Run it

```sh
docker run --name mypipeline -e POSTGRES_PASSWORD=yourpassword -p 5432:5432 -d tarmac
```

Hack into the bash

```sh
docker exec -it mypipeline bash
```

## OSM Data extraction

The OSM data will be automatically downloaded from download.geofabrik.de.
It is also possible to extract even smaller areas with osmium. For this you need the relation id from OSM for a multipolygon.

Then you can run, for example:

```sh
osmium extract -p bb-boundary.osm stuttgart-regbez-latest.osm.pbf -o bietigheim-bissingen.pbf
```

See also [Osmium Tool Manual](https://osmcode.org/osmium-tool/manual.html#creating-geographic-extracts).

## 💛 Thanks to

This repo is highly inspired by and is containing code from [gislars/osm-parking-processing](https://github.com/gislars/osm-parking-processing/tree/wip)
