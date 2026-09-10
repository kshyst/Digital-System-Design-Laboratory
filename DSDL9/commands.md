# اجرای تست‌های DSDL9 و مشاهده در GTKWave

این دستورها باید از ریشه مخزن `Digital-System-Design-Laboratory` اجرا شوند.

سه تست‌بنچ طوری تنظیم شده‌اند که هنگام اجرا فایل VCD متناظر خود را تولید کنند. خروجی‌های کامپایل و موج‌ها در `DSDL9/build/` قرار می‌گیرند.

## تست تطبیق دقیق

### کامپایل و اجرا

در ترمینال و از ریشه مخزن اجرا کنید:

```bash
mkdir -p DSDL9/build
iverilog -g2012 -Wall \
  -s tb_tcam_exact \
  -o DSDL9/build/tb_tcam_exact.vvp \
  DSDL9/tcam_entry.v \
  DSDL9/tcam.v \
  DSDL9/tb_tcam_exact.v
(cd DSDL9/build && vvp ./tb_tcam_exact.vvp)
```

خروجی موفق باید شامل این پیام باشد:

```text
PASS: exact TCAM matching
```

### بازکردن موج

از ریشه مخزن اجرا کنید:

```bash
gtkwave DSDL9/build/tb_tcam_exact.vcd
```

### سیگنال‌هایی که باید به Wave اضافه شوند

در پنل `SST`، ماژول `tb_tcam_exact` را باز کنید و این سیگنال‌ها را با `Append` یا `Insert` اضافه کنید:

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

برای بررسی داخلی ورودی شماره ۱۵، مسیر زیر را نیز باز کنید:

```text
dut
entries[15]
entry
```

و این سیگنال‌ها را اضافه کنید:

```text
valid
stored_data
stored_x_mask
mismatched_bits
match
```

برای باس‌های زیر، با کلیک راست گزینه `Data Format > Hex` را انتخاب کنید:

```text
write_address
write_data
write_x_mask
search_data
match_lines
stored_data
stored_x_mask
mismatched_bits
```

### مقادیر مورد انتظار در Wave

```text
write_address = F
write_data    = A55A
write_x_mask  = 0000
```

پس از لبه ساعت نوشتن:

```text
valid       = 1
stored_data = A55A
```

برای جست‌وجوی مقدار برابر:

```text
search_data = A55A
match_lines = 8000
match       = 1
```

تنها بیت ۱۵ خروجی `match_lines` باید یک باشد.

برای مقدار متفاوت:

```text
search_data = A55B
match_lines = 0000
match       = 0
```

---

## تست Reset

### کامپایل و اجرا

در ترمینال و از ریشه مخزن اجرا کنید:

```bash
mkdir -p DSDL9/build
iverilog -g2012 -Wall \
  -s tb_tcam_reset \
  -o DSDL9/build/tb_tcam_reset.vvp \
  DSDL9/tcam_entry.v \
  DSDL9/tcam.v \
  DSDL9/tb_tcam_reset.v
(cd DSDL9/build && vvp ./tb_tcam_reset.vvp)
```

خروجی موفق باید شامل این پیام باشد:

```text
PASS: reset invalidates TCAM entries
```

### بازکردن موج

از ریشه مخزن اجرا کنید:

```bash
gtkwave DSDL9/build/tb_tcam_reset.vcd
```

### سیگنال‌هایی که باید به Wave اضافه شوند

از ماژول `tb_tcam_reset` این سیگنال‌ها را اضافه کنید:

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

برای دیدن اثر Reset روی ورودی صفر، این مسیر را باز کنید:

```text
dut
entries[0]
entry
```

و این سیگنال‌ها را اضافه کنید:

```text
valid
stored_data
stored_x_mask
match
```

باس‌های `write_address`، `write_data`، `write_x_mask`، `search_data`، `match_lines`، `stored_data` و `stored_x_mask` را روی نمایش `Hex` قرار دهید.

### مقادیر مورد انتظار در Wave

در زمان نوشتن ورودی صفر:

```text
write_address = 0
write_data    = A
write_x_mask  = 0
search_data   = A
write_enable  = 1
```

بعد از لبه ساعت نوشتن:

```text
valid       = 1
match       = 1
match_lines = 1
```

هنگام فعال‌شدن دوباره Reset:

```text
reset       = 1
valid       = 0
match       = 0
match_lines = 0
```

داده ذخیره‌شده ممکن است پس از Reset همچنان مقدار قبلی را نگه دارد، اما چون `valid=0` است نباید هیچ تطبیقی تولید شود.

---

## تست Wildcard یا تطبیق سه‌حالته

### کامپایل و اجرا

در ترمینال و از ریشه مخزن اجرا کنید:

```bash
mkdir -p DSDL9/build
iverilog -g2012 -Wall \
  -s tb_tcam_wildcard \
  -o DSDL9/build/tb_tcam_wildcard.vvp \
  DSDL9/tcam_entry.v \
  DSDL9/tcam.v \
  DSDL9/tb_tcam_wildcard.v
(cd DSDL9/build && vvp ./tb_tcam_wildcard.vvp)
```

خروجی موفق باید شامل این پیام باشد:

```text
PASS: ternary wildcard matching
```

### بازکردن موج

از ریشه مخزن اجرا کنید:

```bash
gtkwave DSDL9/build/tb_tcam_wildcard.vcd
```

### سیگنال‌هایی که باید به Wave اضافه شوند

از ماژول `tb_tcam_wildcard` این سیگنال‌ها را اضافه کنید:

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

برای دیدن محتوای سه ورودی نوشته‌شده، مسیرهای زیر را باز کنید:

```text
dut > entries[0] > entry
dut > entries[1] > entry
dut > entries[2] > entry
```

از هر ورودی این سیگنال‌ها را اضافه کنید:

```text
valid
stored_data
stored_x_mask
mismatched_bits
match
```

باس‌ها را روی `Data Format > Hex` یا برای مشاهده الگوی X روی `Data Format > Binary` قرار دهید.

### مقادیر نوشته‌شده در سه ورودی

```text
Entry 0:
stored_data   = 60
stored_x_mask = 0F
Pattern       = 0110XXXX

Entry 1:
stored_data   = 68
stored_x_mask = 87
Pattern       = X1101XXX

Entry 2:
stored_data   = 2C
stored_x_mask = 52
Pattern       = 0X1X11X0
```

در `stored_x_mask`، بیت یک یعنی همان موقعیت در مقایسه نادیده گرفته می‌شود.

### مقادیر مورد انتظار در Wave

برای ورودی مشترک سه الگو:

```text
search_data = 6E
match_lines = 7
```

نمایش دودویی خروجی باید چنین باشد:

```text
match_lines = 0111
```

یعنی ورودی‌های صفر، یک و دو هم‌زمان تطبیق دارند و ورودی سه نامعتبر است.

برای ورودی نامنطبق:

```text
search_data = FF
match_lines = 0
```

نمایش دودویی:

```text
match_lines = 0000
```

---

## اجرای هر سه تست پشت سر هم

در ترمینال و از ریشه مخزن اجرا کنید:

```bash
mkdir -p DSDL9/build

iverilog -g2012 -Wall -s tb_tcam_exact \
  -o DSDL9/build/tb_tcam_exact.vvp \
  DSDL9/tcam_entry.v DSDL9/tcam.v DSDL9/tb_tcam_exact.v
(cd DSDL9/build && vvp ./tb_tcam_exact.vvp)

iverilog -g2012 -Wall -s tb_tcam_reset \
  -o DSDL9/build/tb_tcam_reset.vvp \
  DSDL9/tcam_entry.v DSDL9/tcam.v DSDL9/tb_tcam_reset.v
(cd DSDL9/build && vvp ./tb_tcam_reset.vvp)

iverilog -g2012 -Wall -s tb_tcam_wildcard \
  -o DSDL9/build/tb_tcam_wildcard.vvp \
  DSDL9/tcam_entry.v DSDL9/tcam.v DSDL9/tb_tcam_wildcard.v
(cd DSDL9/build && vvp ./tb_tcam_wildcard.vvp)
```

سپس فایل‌های موج را جداگانه باز کنید. هر فرمان را پس از بستن پنجره قبلی اجرا کنید:

```bash
gtkwave DSDL9/build/tb_tcam_exact.vcd
gtkwave DSDL9/build/tb_tcam_reset.vcd
gtkwave DSDL9/build/tb_tcam_wildcard.vcd
```

پس از بازشدن GTKWave، برای دیدن کل بازه شبیه‌سازی از گزینه `Time > Zoom > Zoom Full` استفاده کنید.
