/*!\file misc_str.h
 */
#ifndef _w32_MISC_STR_H
#define _w32_MISC_STR_H

extern  char   *str_lcpy     (char *dst, const char *src, size_t len);
extern  char   *str_replace  (int ch1, int ch2, char *str);
extern  size_t  str_ntrimcpy (char *dst, const char *src, size_t len);
extern  char   *str_rtrim    (char *src);
extern  char   *str_ltrim    (const char *src);
extern  char   *str_trim     (const char *orig, char *dest, size_t len);
extern  char   *str_reverse  (char *src);
extern char    *str_tok      (char *ptr, const char *sep, char **end);
extern  BYTE    str_atox     (const char *src);

#if defined(WIN32) || defined(WIN64)
  #define astr_acp   W32_NAMESPACE (astr_acp)
  #define astr_utf8  W32_NAMESPACE (astr_utf8)
  #define wstr_utf8  W32_NAMESPACE (wstr_utf8)
  #define wstr_acp   W32_NAMESPACE (wstr_acp)

  extern const char    *wstr_acp  (const wchar_t *in_str);
  extern const char    *wstr_utf8 (const wchar_t *in_str);
  extern const wchar_t *astr_acp  (const char *in_str);
  extern const wchar_t *astr_utf8 (const char *in_str);
#endif

#endif

