# اجرای تست‌های DSDL9 و مشاهده موج‌ها در GTKWave

> تمام دستورهای این فایل باید داخل پوشه `DSDL9` اجرا شوند.
>
> فایل اجرایی موقت `.vvp` برای اجرای شبیه‌سازی لازم است، اما در `/tmp` ساخته و بلافاصله حذف می‌شود. فقط فایل‌های `.vcd` در `DSDL9/build/` باقی می‌مانند.

## ۱. ورود به پوشه و بررسی ابزارها

این بلوک را از ریشه مخزن `Digital-System-Design-Laboratory` اجرا کنید:

```bash
cd DSDL9
mkdir -p build
command -v iverilog
command -v vvp
command -v gtkwave
```

سه مسیر ابزار باید نمایش داده شوند. در Ubuntu، اگر ابزاری نصب نیست، اجرا کنید:

```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave
```

تست‌بنچ‌ها باید شامل دستورهای `$dumpfile` و `$dumpvars` باشند. از داخل `DSDL9` بررسی کنید:

```bash
grep -n '\$dumpfile\|\$dumpvars' tb_tcam_exact.v tb_tcam_reset.v tb_tcam_wildcard.v
```

باید برای هر تست‌بنچ هر دو دستور دیده شوند. اگر خروجی خالی است، از نسخه قدیمی تست‌بنچ‌ها استفاده می‌کنید و باید فایل‌های جدید موجود در ZIP را جایگزین کنید.

---

# تست اول: تطبیق دقیق

## کامپایل، اجرا و بررسی ساخت VCD

این بلوک را داخل پوشه `DSDL9` اجرا کنید:

```bash
mkdir -p build
rm -f /tmp/tb_tcam_exact.vvp build/tb_tcam_exact.vcd
iverilog -g2012 -Wall \
  -s tb_tcam_exact \
  -o /tmp/tb_tcam_exact.vvp \
  tcam_entry.v \
  tcam.v \
  tb_tcam_exact.v
vvp /tmp/tb_tcam_exact.vvp
rm -f /tmp/tb_tcam_exact.vvp
test -s build/tb_tcam_exact.vcd
printf 'VCD created: %s\n' "$PWD/build/tb_tcam_exact.vcd"
```

خروجی موفق باید شامل هر دو پیام باشد:

```text
PASS: exact TCAM matching
VCD created: .../DSDL9/build/tb_tcam_exact.vcd
```

## بازکردن GTKWave

داخل پوشه `DSDL9` اجرا کنید:

```bash
gtkwave "$PWD/build/tb_tcam_exact.vcd"
```

## سیگنال‌هایی که باید اضافه شوند

در پنل `SST`، ماژول `tb_tcam_exact` را باز و این سیگنال‌ها را `Append` کنید:

```text
clk
reset
write_enable
write_address
write_data
write_x_mask
search_data
match_lines
```

برای مشاهده ورودی شماره ۱۵، این مسیر را باز کنید:

```text
tb_tcam_exact > dut > entries[15] > entry
```

این سیگنال‌ها را نیز اضافه کنید:

```text
valid
stored_data
stored_x_mask
mismatched_bits
match
```

باس‌ها را با کلیک راست روی `Data Format > Hex` قرار دهید.

## مقادیر مورد انتظار

هنگام نوشتن:

```text
write_address = F
write_data = A55A
write_x_mask = 0000
write_enable = 1
```

پس از لبه بالارونده ساعت:

```text
valid = 1
stored_data = A55A
```

هنگام جست‌وجوی مقدار برابر:

```text
search_data = A55A
match_lines = 8000
match = 1
```

هنگام جست‌وجوی مقدار متفاوت:

```text
search_data = A55B
match_lines = 0000
match = 0
```

---

# تست دوم: Reset

## کامپایل، اجرا و بررسی ساخت VCD

این بلوک را داخل پوشه `DSDL9` اجرا کنید:

```bash
mkdir -p build
rm -f /tmp/tb_tcam_reset.vvp build/tb_tcam_reset.vcd
iverilog -g2012 -Wall \
  -s tb_tcam_reset \
  -o /tmp/tb_tcam_reset.vvp \
  tcam_entry.v \
  tcam.v \
  tb_tcam_reset.v
vvp /tmp/tb_tcam_reset.vvp
rm -f /tmp/tb_tcam_reset.vvp
test -s build/tb_tcam_reset.vcd
printf 'VCD created: %s\n' "$PWD/build/tb_tcam_reset.vcd"
```

خروجی موفق:

```text
PASS: reset invalidates TCAM entries
VCD created: .../DSDL9/build/tb_tcam_reset.vcd
```

## بازکردن GTKWave

داخل پوشه `DSDL9` اجرا کنید:

```bash
gtkwave "$PWD/build/tb_tcam_reset.vcd"
```

## سیگنال‌هایی که باید اضافه شوند

از `tb_tcam_reset` اضافه کنید:

```text
clk
reset
write_enable
write_address
write_data
write_x_mask
search_data
match_lines
```

سپس این مسیر را باز کنید:

```text
tb_tcam_reset > dut > entries[0] > entry
```

این سیگنال‌ها را اضافه کنید:

```text
valid
stored_data
stored_x_mask
match
```

باس‌ها را روی `Data Format > Hex` قرار دهید.

## مقادیر مورد انتظار

پس از نوشتن ورودی صفر:

```text
write_address = 0
write_data = A
write_x_mask = 0
search_data = A
valid = 1
match_lines = 1
```

پس از فعال‌شدن مجدد Reset و رسیدن لبه ساعت:

```text
reset = 1
valid = 0
match = 0
match_lines = 0
```

ممکن است `stored_data` همچنان مقدار `A` را نگه دارد، اما چون `valid=0` است هیچ تطبیقی تولید نمی‌شود.

---

# تست سوم: Wildcard

## کامپایل، اجرا و بررسی ساخت VCD

این بلوک را داخل پوشه `DSDL9` اجرا کنید:

```bash
mkdir -p build
rm -f /tmp/tb_tcam_wildcard.vvp build/tb_tcam_wildcard.vcd
iverilog -g2012 -Wall \
  -s tb_tcam_wildcard \
  -o /tmp/tb_tcam_wildcard.vvp \
  tcam_entry.v \
  tcam.v \
  tb_tcam_wildcard.v
vvp /tmp/tb_tcam_wildcard.vvp
rm -f /tmp/tb_tcam_wildcard.vvp
test -s build/tb_tcam_wildcard.vcd
printf 'VCD created: %s\n' "$PWD/build/tb_tcam_wildcard.vcd"
```

خروجی موفق:

```text
PASS: ternary wildcard matching
VCD created: .../DSDL9/build/tb_tcam_wildcard.vcd
```

## بازکردن GTKWave

داخل پوشه `DSDL9` اجرا کنید:

```bash
gtkwave "$PWD/build/tb_tcam_wildcard.vcd"
```

## سیگنال‌هایی که باید اضافه شوند

از `tb_tcam_wildcard` اضافه کنید:

```text
clk
reset
write_enable
write_address
write_data
write_x_mask
search_data
match_lines
```

برای دیدن سه ورودی نوشته‌شده، مسیرهای زیر را باز کنید:

```text
tb_tcam_wildcard > dut > entries[0] > entry
tb_tcam_wildcard > dut > entries[1] > entry
tb_tcam_wildcard > dut > entries[2] > entry
```

از هر ورودی اضافه کنید:

```text
valid
stored_data
stored_x_mask
mismatched_bits
match
```

`stored_data`، `write_data` و `search_data` را روی `Hex` و در صورت نیاز ماسک‌ها را روی `Binary` قرار دهید.

## مقادیر مورد انتظار

سه ورودی نوشته‌شده:

```text
Entry 0: stored_data=60, stored_x_mask=0F, pattern=0110XXXX
Entry 1: stored_data=68, stored_x_mask=87, pattern=X1101XXX
Entry 2: stored_data=2C, stored_x_mask=52, pattern=0X1X11X0
```

برای جست‌وجوی مشترک:

```text
search_data = 6E
match_lines = 7
```

نمایش دودویی `match_lines` باید باشد:

```text
0111
```

برای جست‌وجوی نامنطبق:

```text
search_data = FF
match_lines = 0
```

نمایش دودویی:

```text
0000
```

---

# اجرای هر سه تست با یک بلوک

این بلوک را داخل پوشه `DSDL9` اجرا کنید:

```bash
mkdir -p build
rm -f /tmp/tb_tcam_exact.vvp /tmp/tb_tcam_reset.vvp /tmp/tb_tcam_wildcard.vvp build/*.vcd

iverilog -g2012 -Wall -s tb_tcam_exact \
  -o /tmp/tb_tcam_exact.vvp \
  tcam_entry.v tcam.v tb_tcam_exact.v
vvp /tmp/tb_tcam_exact.vvp
rm -f /tmp/tb_tcam_exact.vvp

iverilog -g2012 -Wall -s tb_tcam_reset \
  -o /tmp/tb_tcam_reset.vvp \
  tcam_entry.v tcam.v tb_tcam_reset.v
vvp /tmp/tb_tcam_reset.vvp
rm -f /tmp/tb_tcam_reset.vvp

iverilog -g2012 -Wall -s tb_tcam_wildcard \
  -o /tmp/tb_tcam_wildcard.vvp \
  tcam_entry.v tcam.v tb_tcam_wildcard.v
vvp /tmp/tb_tcam_wildcard.vvp
rm -f /tmp/tb_tcam_wildcard.vvp

test -s build/tb_tcam_exact.vcd
test -s build/tb_tcam_reset.vcd
test -s build/tb_tcam_wildcard.vcd
printf 'All tests passed and all VCD files were created.\n'
```

# اگر GTKWave باز نشد

ابتدا وجود فایل را بررسی کنید:

```bash
pwd
ls -lh build/*.vcd
```

سپس محیط گرافیکی را بررسی کنید:

```bash
printf 'DISPLAY=%s\nWAYLAND_DISPLAY=%s\n' "$DISPLAY" "$WAYLAND_DISPLAY"
```

## Linux دارای دسکتاپ

داخل پوشه `DSDL9` اجرا کنید:

```bash
gtkwave "$PWD/build/tb_tcam_exact.vcd"
```

## WSL با GTKWave نصب‌شده در Windows

اگر فرمان `gtkwave.exe` در دسترس است، اجرا کنید:

```bash
gtkwave.exe "$(wslpath -w "$PWD/build/tb_tcam_exact.vcd")"
```

اگر پیام زیر را دریافت کردید:

```text
Could not initialize GTK! Is DISPLAY env var/xhost set?
```

فایل VCD سالم است، اما ترمینال شما نمایشگر گرافیکی ندارد. در اتصال SSH یا سرور بدون دسکتاپ، فایل `build/*.vcd` را به سیستم دارای محیط گرافیکی منتقل و آن را در GTKWave محلی باز کنید.

پس از بازشدن GTKWave، از `Time > Zoom > Zoom Full` استفاده کنید تا کل شبیه‌سازی دیده شود.
