-- Goal:
-- ======
-- Data set about "Oberflächenqualität" which we consider a combination of `surface` and `smoothness` data.

-- Visualization
-- =====
-- 1. Map of smoothness data
-- 2. Map of surface data

-- Hidden complexity
-- =====
-- There is a hidden complexity in this task having to do with "cycleway:*" and "sidewalk:*" tagging.
-- (AKA bike and pedestiran infrastructure that is mapped on the "centerline".)
-- In my proof of concept, I tried to handle this with complex hierachical keys.
-- However, with the power of PostgreSQL, a better approach is likely to first split the data and then process it.
-- A "centerline" with "sidewalk=both" (or "sidewalk:both=yes") would become 3 lines, with the two sidewalk lines being moved to the left/right of the centerline. Same for "cycleway*". Possible keys like "cycleway:left:surface=*" need to be moved as well.
-- Its recommended to first pre-process the data in LUA to normalize the tagging of "sidewalk=both" and "sidewalk:both=yes" to a "sidewalk:left+sidewalk:right" patter, so in SQL we only need to deal with explicit left/right.
-- UPDATE 2022-09-21: See "bicycleRoadInfrastructure.lua" for my latest idea how to setup a process for this.

-- Processing
-- ====
-- We interpolate surface and smoothness data in order to show a complete map.
-- We also show a confidence and confidence-description for those fields.
--
-- 1. If smoothness present, normalize the data.
-- This will reduce the values to a list that we support.
-- See https://github.com/FixMyBerlin/osm-scripts/blob/main/utils/Highways-SurfaceData/utils/normalizedSmoothness.ts
--    confidence: high
--    conficence-description: explicit tagging OR explicit tagging, normalized
--      I use a different approach in the script above, which documents the tag modification in "before => after" pattern, which is probably the better idea.
--      See https://github.com/FixMyBerlin/osm-scripts/blob/main/utils/Highways-SurfaceData/utils/addCustomSmoothnessProps.ts#L78
-- Note, that the normalization (and other transponation) can have two list: One main list and one to be used to add "_todos" in a separate data layer.
--
-- 2. If no smoothness is given, use surface to extrapolate a smoothness value
-- See https://github.com/FixMyBerlin/osm-scripts/blob/main/utils/Highways-SurfaceData/utils/extrapolatedSmoothnessBasedOnSurface.ts
-- Again, the second list might be re-used for a "todoList".
--
-- 3. If no surface is given, use the highway (type) to exptrapolate a surface/smoothness value.
-- See https://github.com/FixMyBerlin/osm-scripts/blob/main/utils/Highways-SurfaceData/utils/extrapolatedSmoothnessBasedOnHighway.ts
