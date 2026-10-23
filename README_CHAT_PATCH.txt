Phaung Home Repair — Direct Customer ↔ Admin Chat Patch

Included source files:
- lib/screens/chat/customer_support_chat_screen.dart
- lib/screens/admin/admin_chat_inbox_screen.dart
- lib/screens/admin/admin_chat_screen.dart
- lib/routes/app_router.dart (updated)
- lib/screens/customer/customer_home_screen.dart (updated)
- lib/screens/admin/admin_home_screen.dart (updated)
- firestore_chat_rules_snippet.txt

Install:
1. Back up your current project first.
2. Extract this ZIP into the Flutter project root and merge/overwrite the listed lib files.
3. Open firestore_chat_rules_snippet.txt. Merge its functions and match blocks into your EXISTING Firestore rules. Do not replace all existing rules with the snippet.
4. Confirm every admin account has users/{adminUid}.role == "admin" in Firestore. Rules rely on this exact role field.
5. Run:
   flutter pub get
   flutter analyze
   flutter run

Routes added:
- Customer: /customer/chat
- Admin inbox: /admin/chats
- Admin conversation: /admin/chats/{customerUid}

Firestore structure:
- chats/{customerUid}
- chats/{customerUid}/messages/{messageId}

Notes:
- The chat document ID is the customer's Firebase Auth UID, so each customer has a separate conversation.
- This patch supports text messages and live Firestore streams. It does not include image/file attachments or push notifications.
- The existing older service_requests/{requestId}/chats path is not migrated by this patch.
- Verify your Firestore rules carefully before publishing. Existing rules for other app collections must remain intact.
