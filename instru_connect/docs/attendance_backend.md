# Session-Based Attendance Backend

## Collections

### `sessions`
- `sessionId`
- `subjectId`
- `facultyId`
- `batchId`
- `date`
- `startTime`
- `endTime`
- `status`
- `createdAt`
- `updatedAt`

### `attendance`
- `attendanceId`
- `sessionId`
- `subjectId`
- `facultyId`
- `batchId`
- `studentId`
- `status`
- `markedAt`
- `markedBy`

### `attendance_summary`
- `studentId`
- `subjectId`
- `batchId`
- `totalSessions`
- `presentCount`
- `lateCount`
- `attendancePercentage`
- `lastUpdated`

## Routes

Base function: `/attendanceApi`

- `POST /sessions`
- `PATCH /sessions/:id/close`
- `GET /sessions?subject_id=&batch_id=&date=&status=&limit=&cursor=`
- `POST /attendance/bulk`
- `GET /attendance/student/:id?limit=&cursor=`
- `GET /attendance/subject/:student_id/:subject_id?limit=&cursor=`
- `GET /attendance/summary/:student_id`
- `GET /attendance/defaulters?threshold=75&subject_id=&batch_id=&limit=`

Legacy compatibility:
- `POST /sessions/create`
- `POST /attendance/mark`
- `GET /sessions/:subject_id`

## Folder Structure

```text
functions/
  index.js
  src/
    controllers/
    repositories/
    routes/
    services/
    shared/
```

## Notes

- Attendance uses deterministic ids: `sessionId_studentId`
- Bulk marking is idempotent-safe for retries
- Attendance percentages are derived from `attendance_summary`
- Notifications are created after bulk marking and low-attendance updates
