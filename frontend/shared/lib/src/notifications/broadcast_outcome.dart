/// A saved broadcast is not proof of delivery to a recipient.
class BroadcastOutcome {
  final String? status;
  const BroadcastOutcome(this.status);

  String get label => switch (status) {
    'scheduled' => 'Scheduled',
    'pending' => 'Pending delivery',
    'uncertain' => 'Delivery needs review',
    'accepted' => 'Accepted by provider',
    'simulated' => 'Simulated — not sent',
    'partial' => 'Partially accepted',
    'failed' => 'Delivery failed',
    'delivered' => 'Delivery confirmed',
    'read' => 'Read receipt received',
    'sent' => 'Legacy send — unconfirmed',
    _ => 'Delivery unconfirmed',
  };

  String get description => switch (status) {
    'scheduled' => 'Saved for the scheduled time. Delivery has not started.',
    'pending' => 'Saved and awaiting processing. Delivery is not confirmed.',
    'uncertain' => 'Some outcomes are unknown. Do not resend until delivery attempts have been reviewed.',
    'accepted' => 'The provider accepted the request. Recipient delivery is not confirmed.',
    'simulated' => 'No message was sent. This channel has no configured delivery provider.',
    'partial' => 'Only some attempts were accepted. Review delivery details before retrying.',
    'failed' => 'The broadcast was saved, but no attempt was accepted. Check recipients and provider setup.',
    'delivered' => 'A delivery receipt was recorded.',
    'read' => 'A read receipt was recorded.',
    _ => 'The broadcast was saved. Its delivery outcome is not confirmed.',
  };
}
