// Copyright 2026 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

import 'dart:convert';

/// JSON that is safe to inline in a `<script>` element or a script source.
String scriptSafeJson(Object value) =>
    jsonEncode(value)
        .replaceAll('<', r'\u003c')
        .replaceAll('\u2028', r'\u2028')
        .replaceAll('\u2029', r'\u2029');
