import 'package:flutter/material.dart';
import 'colors.dart';

// Matches Type.kt sp values exactly.
// Used directly when MaterialTheme.of(context).textTheme isn't convenient.
const kBodyLarge = TextStyle(
  fontSize: 16,
  height: 23 / 16,
  color: kTextPrimary,
  fontWeight: FontWeight.normal,
);

const kBodyMedium = TextStyle(
  fontSize: 14,
  height: 20 / 14,
  color: kTextSecondary,
  fontWeight: FontWeight.normal,
);

const kBodySmall = TextStyle(
  fontSize: 13,
  height: 18 / 13,
  color: kTextSecondary,
  fontWeight: FontWeight.normal,
);

const kTitleMedium = TextStyle(
  fontSize: 16,
  height: 22 / 16,
  color: kTextPrimary,
  fontWeight: FontWeight.w600,
);

const kLabelSmall = TextStyle(
  fontSize: 12,
  height: 16 / 12,
  color: kTextSecondary,
  fontWeight: FontWeight.normal,
);

// Inbox row — hardcoded sizes (14sp sender/subject, 13sp timestamp)
const kInboxSender = TextStyle(
  fontSize: 14,
  color: kTextPrimary,
  fontWeight: FontWeight.normal,
);

const kInboxSubject = TextStyle(
  fontSize: 14,
  color: kTextPrimary,
  fontWeight: FontWeight.normal,
);

const kInboxTimestamp = TextStyle(
  fontSize: 13,
  color: kTextSecondary,
  fontWeight: FontWeight.normal,
);
