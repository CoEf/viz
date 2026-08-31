extends Node

## Periodic GPU→CPU readback of the dirt mask to compute cleaning progress.
##
## Downsamples to SAMPLE_RES×SAMPLE_RES before iterating pixels so the
## CPU work is negligible. Reports via signals; does not touch the UI itself.

signal progress_updated(pct: float)
signal level_cleared

const SAMPLE_RES := 32        # downsample grid (1024 pixels to iterate)
const CHECK_INTERVAL := 1.0   # seconds between readbacks
const CLEAR_THRESHOLD := 0.02 # avg dirt ≤ 2% → level complete

var _dirt_mask: DrawableTexture2D
var _coverage_mask: DrawableTexture2D  # R=1 = triangle, R=0 = empty UV space
var _timer: float = 0.0
var _cleared: bool = false


func setup(dirt_mask: DrawableTexture2D) -> void:
	_dirt_mask = dirt_mask
	# Emit initial 0% so the HUD shows a value immediately
	progress_updated.emit(0.0)
	_timer = 0.5  # first real sample after 0.5 s (let GPU settle)


func set_coverage_mask(mask: DrawableTexture2D) -> void:
	_coverage_mask = mask


func _process(delta: float) -> void:
	if _dirt_mask == null or _cleared:
		return

	_timer -= delta
	if _timer > 0.0:
		return

	_timer = CHECK_INTERVAL
	_sample()


func _sample() -> void:
	var img_dirt := _dirt_mask.get_image()
	if img_dirt == null:
		push_warning("ProgressComponent: get_image() returned null — progress cannot be tracked")
		return

	img_dirt.resize(SAMPLE_RES, SAMPLE_RES, Image.INTERPOLATE_BILINEAR)

	var avg_dirt: float
	if _coverage_mask != null:
		var img_cov := _coverage_mask.get_image()
		if img_cov != null:
			img_cov.resize(SAMPLE_RES, SAMPLE_RES, Image.INTERPOLATE_BILINEAR)
			var covered := 0.0
			var dirty := 0.0
			for y in SAMPLE_RES:
				for x in SAMPLE_RES:
					var c := img_cov.get_pixel(x, y).r
					covered += c
					dirty += img_dirt.get_pixel(x, y).r * c
			# avg_dirt over covered pixels only; uncovered UV space is ignored.
			avg_dirt = dirty / maxf(covered, 1.0)
		else:
			avg_dirt = _unweighted_avg(img_dirt)
	else:
		avg_dirt = _unweighted_avg(img_dirt)

	var pct := clampf((1.0 - avg_dirt) * 100.0, 0.0, 100.0)
	progress_updated.emit(pct)

	if avg_dirt <= CLEAR_THRESHOLD:
		_cleared = true
		level_cleared.emit()


func _unweighted_avg(img: Image) -> float:
	var total := 0.0
	for y in SAMPLE_RES:
		for x in SAMPLE_RES:
			total += img.get_pixel(x, y).r
	return total / float(SAMPLE_RES * SAMPLE_RES)
