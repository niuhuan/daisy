#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_int_32_list {
  int32_t *ptr;
  int32_t len;
} wire_int_32_list;

typedef struct WireSyncReturnStruct {
  uint8_t *ptr;
  int32_t len;
  bool success;
} WireSyncReturnStruct;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

void wire_init(int64_t port_, struct wire_uint_8_list *root);

void wire_desktop_root(int64_t port_);

void wire_http_get(int64_t port_, struct wire_uint_8_list *url);

void wire_save_property(int64_t port_, struct wire_uint_8_list *k, struct wire_uint_8_list *v);

void wire_load_property(int64_t port_, struct wire_uint_8_list *k);

void wire_load_cache_image(int64_t port_,
                           struct wire_uint_8_list *url,
                           struct wire_uint_8_list *useful,
                           int32_t *extends_field_int_first,
                           int32_t *extends_field_int_second,
                           int32_t *extends_field_int_third);

void wire_comic_categories(int64_t port_);

void wire_comic_recommend(int64_t port_);

void wire_comic_update_list(int64_t port_, int64_t sort, int64_t page);

void wire_comic_rank_list(int64_t port_);

void wire_comic_search(int64_t port_, struct wire_uint_8_list *content, int64_t page);

void wire_comic_classify_with_level(int64_t port_,
                                    struct wire_int_32_list *categories,
                                    int64_t sort,
                                    int64_t page);

void wire_comic_detail(int64_t port_, int32_t id);

void wire_comic_chapter_detail(int64_t port_, int32_t comic_id, int32_t chapter_id);

void wire_comment(int64_t port_, int64_t obj_type, int32_t obj_id, bool hot, int64_t page);

void wire_comic_view_page(int64_t port_,
                          int32_t comic_id,
                          int32_t chapter_id,
                          struct wire_uint_8_list *chapter_title,
                          int32_t chapter_order,
                          int32_t page_rank);

void wire_load_comic_view_logs(int64_t port_, int64_t page);

void wire_view_log_by_comic_id(int64_t port_, int32_t comic_id);

void wire_news_categories(int64_t port_);

void wire_news_list(int64_t port_, int64_t id, int64_t page);

void wire_novel_categories(int64_t port_);

void wire_novel_list(int64_t port_, int32_t category, int64_t process, int64_t sort, int64_t page);

void wire_novel_detail(int64_t port_, int32_t id);

void wire_novel_chapters(int64_t port_, int32_t id);

void wire_novel_content(int64_t port_, int32_t volume_id, int32_t chapter_id);

void wire_load_novel_view_logs(int64_t port_, int64_t page);

void wire_view_log_by_novel_id(int64_t port_, int32_t novel_id);

void wire_novel_view_page(int64_t port_,
                          int32_t novel_id,
                          int32_t volume_id,
                          struct wire_uint_8_list *volume_title,
                          int32_t volume_order,
                          int32_t chapter_id,
                          struct wire_uint_8_list *chapter_title,
                          int32_t chapter_order,
                          int64_t progress);

void wire_auto_clean(int64_t port_, int64_t time);

int32_t *new_box_autoadd_i32(int32_t value);

struct wire_int_32_list *new_int_32_list(int32_t len);

struct wire_uint_8_list *new_uint_8_list(int32_t len);

void free_WireSyncReturnStruct(struct WireSyncReturnStruct val);

void store_dart_post_cobject(DartPostCObjectFnType ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_init);
    dummy_var ^= ((int64_t) (void*) wire_desktop_root);
    dummy_var ^= ((int64_t) (void*) wire_http_get);
    dummy_var ^= ((int64_t) (void*) wire_save_property);
    dummy_var ^= ((int64_t) (void*) wire_load_property);
    dummy_var ^= ((int64_t) (void*) wire_load_cache_image);
    dummy_var ^= ((int64_t) (void*) wire_comic_categories);
    dummy_var ^= ((int64_t) (void*) wire_comic_recommend);
    dummy_var ^= ((int64_t) (void*) wire_comic_update_list);
    dummy_var ^= ((int64_t) (void*) wire_comic_rank_list);
    dummy_var ^= ((int64_t) (void*) wire_comic_search);
    dummy_var ^= ((int64_t) (void*) wire_comic_classify_with_level);
    dummy_var ^= ((int64_t) (void*) wire_comic_detail);
    dummy_var ^= ((int64_t) (void*) wire_comic_chapter_detail);
    dummy_var ^= ((int64_t) (void*) wire_comment);
    dummy_var ^= ((int64_t) (void*) wire_comic_view_page);
    dummy_var ^= ((int64_t) (void*) wire_load_comic_view_logs);
    dummy_var ^= ((int64_t) (void*) wire_view_log_by_comic_id);
    dummy_var ^= ((int64_t) (void*) wire_news_categories);
    dummy_var ^= ((int64_t) (void*) wire_news_list);
    dummy_var ^= ((int64_t) (void*) wire_novel_categories);
    dummy_var ^= ((int64_t) (void*) wire_novel_list);
    dummy_var ^= ((int64_t) (void*) wire_novel_detail);
    dummy_var ^= ((int64_t) (void*) wire_novel_chapters);
    dummy_var ^= ((int64_t) (void*) wire_novel_content);
    dummy_var ^= ((int64_t) (void*) wire_load_novel_view_logs);
    dummy_var ^= ((int64_t) (void*) wire_view_log_by_novel_id);
    dummy_var ^= ((int64_t) (void*) wire_novel_view_page);
    dummy_var ^= ((int64_t) (void*) wire_auto_clean);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_i32);
    dummy_var ^= ((int64_t) (void*) new_int_32_list);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturnStruct);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    return dummy_var;
}