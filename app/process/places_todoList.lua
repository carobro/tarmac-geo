package.path = package.path .. ";/app/process/helper/?.lua"
require("Set")
require("FilterTags")
require("ToNumber")
-- require("PrintTable")
require("AddAddress")
require("MergeTable")
require("AddMetadata")
require("AddUrl")

local table = osm2pgsql.define_table({
  name = 'places_todoList',
  ids = { type = 'any', id_column = 'osm_id', type_column = 'osm_type' },
  columns = {
    { column = 'tags', type = 'jsonb' },
    { column = 'geom', type = 'point' },
  }
})

local function ContinueProcess(object)
  local maybe_continue = false
  local continue = false
  object.tags.todos = ""

  -- Docs: https://wiki.openstreetmap.org/wiki/Key:place
  local allowed_values = Set({
    "city",
    "borough",
    "suburb",
    "town",
    "village",
    "hamlet"
  })
  if allowed_values[object.tags.place] then
    maybe_continue = true
  end

  -- Add task to add *population* data.
  if maybe_continue and (not object.tags.population) then
    continue = true
    object.tags.todos = object.tags.todos .. ";TODO add `population`-Tag."
  end

  -- Add task to add *population:date* data.
  -- TODO: Ideally, we would look at the data, but we need to parse that first…
  if maybe_continue and (not object.tags["population:date"]) then
    continue = true
    object.tags.todos = object.tags.todos .. ";TODO add `population:date`-Tag."
  end

  return continue
end

local function ProcessTags(object)
  local allowed_tags = Set({ "todos", "name", "place", "capital", "website", "wikidata", "wikipedia", "population",
    "population:date", "admin_level" })
  FilterTags(object.tags, allowed_tags)
  -- ToNumber(object.tags, Set({ "population" }))
  AddMetadata(object)
end

function osm2pgsql.process_node(object)
  if not ContinueProcess(object) then return end

  ProcessTags(object)
  AddUrl("node", object)

  table:insert({
    tags = object.tags,
    geom = object:as_point()
  })
end

function osm2pgsql.process_way(object)
  if not ContinueProcess(object) then return end
  if not object.is_closed then return end

  ProcessTags(object)
  AddUrl("way", object)

  table:insert({
    tags = object.tags,
    geom = object:as_polygon():centroid()
  })
end

function osm2pgsql.process_relation(object)
  if not ContinueProcess(object) then return end
  if not object.tags.type == 'multipolygon' then return end

  ProcessTags(object)
  AddUrl("relation", object)

  table:insert({
    tags = object.tags,
    geom = object:as_multipolygon():centroid()
  })
end