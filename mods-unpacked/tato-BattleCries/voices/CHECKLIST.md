# Voice generation checklist

Tổng tiến độ: **64/64** nhân vật đã chuyển voice (EN, 10 câu/nhân vật).

Giọng engine **Kokoro** (local, Voicebox) + pitch/effect riêng mỗi nhân vật. File **`.mp3` mono 48kbps** tại `voices/<slug>/<slug>_NN.mp3` (~8.5MB tổng, clip ~1–2s), dùng bởi mod **Battle Cries** (`AudioStreamMP3`, Godot 3.5+). Nội dung lines lấy từ `apps/web/src/content/lore/<slug>.json`. Bản `.wav` gốc bị xoá/gitignore (regen từ Voicebox khi cần). File này bị loại khỏi zip phát hành.

| # | Nhân vật | Giọng | Pitch | Effect | Trạng thái |
|---|---|---|---|---|---|
| 1 | apprentice | am_puck | 0 | base | ✅ đã chuyển (10/10) |
| 2 | arms-dealer | am_eric | +1 | base | ✅ đã chuyển (10/10) |
| 3 | artificer | am_puck | +2 | base | ✅ đã chuyển (10/10) |
| 4 | baby | af_sky | +4 | base | ✅ đã chuyển (10/10) |
| 5 | beast-master | af_nicole | +1 | base | ✅ đã chuyển (10/10) |
| 6 | brawler | am_fenrir | 0 | base | ✅ đã chuyển (10/10) |
| 7 | buccaneer | am_onyx | -3 | deep | ✅ đã chuyển (10/10) |
| 8 | builder | bm_fable | +1 | base | ✅ đã chuyển (10/10) |
| 9 | bull | bm_lewis | -2 | deep | ✅ đã chuyển (10/10) |
| 10 | captain | bm_george | -1 | base | ✅ đã chuyển (10/10) |
| 11 | chef | am_michael | +1 | base | ✅ đã chuyển (10/10) |
| 12 | chunky | am_santa | -1 | base | ✅ đã chuyển (10/10) |
| 13 | crazy | am_echo | +3 | base | ✅ đã chuyển (10/10) |
| 14 | creature | bm_daniel | -2 | menace | ✅ đã chuyển (10/10) |
| 15 | cryptid | af_river | 0 | base | ✅ đã chuyển (10/10) |
| 16 | curious | af_aoede | +2 | base | ✅ đã chuyển (10/10) |
| 17 | cyborg | am_adam | -1 | robotic | ✅ đã chuyển (10/10) |
| 18 | demon | bm_george | -2 | menace | ✅ đã chuyển (10/10) |
| 19 | diver | am_echo | -1 | base | ✅ đã chuyển (10/10) |
| 20 | doctor | af_sarah | 0 | base | ✅ đã chuyển (10/10) |
| 21 | druid | af_kore | -1 | ghostly | ✅ đã chuyển (10/10) |
| 22 | dwarf | bm_lewis | -3 | deep | ✅ đã chuyển (10/10) |
| 23 | engineer | am_eric | 0 | base | ✅ đã chuyển (10/10) |
| 24 | entrepreneur | am_eric | +2 | base | ✅ đã chuyển (10/10) |
| 25 | explorer | am_liam | +2 | base | ✅ đã chuyển (10/10) |
| 26 | farmer | am_michael | -1 | base | ✅ đã chuyển (10/10) |
| 27 | fisherman | bm_daniel | -1 | base | ✅ đã chuyển (10/10) |
| 28 | gangster | am_onyx | -1 | base | ✅ đã chuyển (10/10) |
| 29 | generalist | am_michael | 0 | base | ✅ đã chuyển (10/10) |
| 30 | ghost | af_nova | +1 | ghostly | ✅ đã chuyển (10/10) |
| 31 | gladiator | bm_fable | 0 | base | ✅ đã chuyển (10/10) |
| 32 | glutton | am_santa | 0 | base | ✅ đã chuyển (10/10) |
| 33 | golem | bm_lewis | -4 | deep | ✅ đã chuyển (10/10) |
| 34 | hiker | am_liam | 0 | base | ✅ đã chuyển (10/10) |
| 35 | hunter | am_onyx | -2 | base | ✅ đã chuyển (10/10) |
| 36 | jack | am_fenrir | +2 | base | ✅ đã chuyển (10/10) |
| 37 | king | bm_george | 0 | base | ✅ đã chuyển (10/10) |
| 38 | knight | bm_daniel | 0 | base | ✅ đã chuyển (10/10) |
| 39 | lich | am_echo | -2 | ghostly | ✅ đã chuyển (10/10) |
| 40 | loud | bm_lewis | 0 | loud | ✅ đã chuyển (10/10) |
| 41 | lucky | af_sky | +2 | base | ✅ đã chuyển (10/10) |
| 42 | mage | bf_isabella | 0 | base | ✅ đã chuyển (10/10) |
| 43 | masochist | af_jessica | -1 | base | ✅ đã chuyển (10/10) |
| 44 | multitasker | af_bella | +2 | base | ✅ đã chuyển (10/10) |
| 45 | mutant | am_puck | +1 | base | ✅ đã chuyển (10/10) |
| 46 | ogre | bm_george | -3 | deep | ✅ đã chuyển (10/10) |
| 47 | old | am_santa | -2 | base | ✅ đã chuyển (10/10) |
| 48 | one-armed | am_echo | 0 | base | ✅ đã chuyển (10/10) |
| 49 | pacifist | af_heart | 0 | base | ✅ đã chuyển (10/10) |
| 50 | ranger | am_onyx | 0 | base | ✅ đã chuyển (10/10) |
| 51 | renegade | am_fenrir | +1 | base | ✅ đã chuyển (10/10) |
| 52 | romantic | bf_emma | +1 | base | ✅ đã chuyển (10/10) |
| 53 | sailor | bm_lewis | -1 | base | ✅ đã chuyển (10/10) |
| 54 | saver | af_kore | +1 | base | ✅ đã chuyển (10/10) |
| 55 | sick | am_liam | +1 | base | ✅ đã chuyển (10/10) |
| 56 | soldier | am_adam | -1 | base | ✅ đã chuyển (10/10) |
| 57 | speedy | am_puck | +3 | base | ✅ đã chuyển (10/10) |
| 58 | streamer | af_nova | +2 | base | ✅ đã chuyển (10/10) |
| 59 | technomage | am_echo | -1 | robotic | ✅ đã chuyển (10/10) |
| 60 | vagabond | am_eric | -1 | base | ✅ đã chuyển (10/10) |
| 61 | vampire | bf_alice | -1 | menace | ✅ đã chuyển (10/10) |
| 62 | well-rounded | am_adam | 0 | base | ✅ đã chuyển (10/10) |
| 63 | wildling | am_fenrir | -1 | base | ✅ đã chuyển (10/10) |
| 64 | wounded | af_river | -1 | ghostly | ✅ đã chuyển (10/10) |
