# SafeRider — Phase 1 Stabilization

This version starts the SafeRider migration toward Firebase-backed production architecture.

## What changed

- Firebase Authentication is now the single login mechanism for Parent, Driver, and Admin.
- The hard-coded `admin/admin` login has been removed.
- Passwords were removed from `Parent` and `Driver` application models.
- Parent → Student is now represented by `Student.parentId`.
- Driver → Student is now represented by `Student.driverId`.
- `Parent.children` was removed to eliminate duplicated relationship state.
- Rides now reference `studentId` and `driverId` instead of copying names.
- Added explicit ride status lifecycle.
- The app root now follows Firebase authentication state instead of a local `loggedInRole` binding.
- Parent and Driver dashboards now use the authenticated account/profile rather than `parents.first` or array index `0`.
- Student assignment screens now support both parent and driver assignment.
- Driver ride actions update a real `Ride` record in the local cache.
- Local JSON remains as a temporary cache during the migration. It is NOT the final production persistence layer.

## Important Firebase setup

Create an administrator user in Firebase Authentication and give that user's document in `users/{uid}`:

```text
email: your-admin-email
role: admin
```

Parent and Driver registration creates:

```text
users/{uid}
parents/{uid}
drivers/{uid}
```

The next phase will make Firestore the authoritative application database and add Firestore security rules.

## Validation performed

All Swift source files were checked with Swift's parser in this environment. A full iOS/Xcode build must still be performed on macOS with Xcode because the Linux environment cannot link SwiftUI/UIKit/Firebase iOS frameworks.
