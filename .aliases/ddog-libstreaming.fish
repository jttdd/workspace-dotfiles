# Resolve the current dd-source worktree root by walking up from $PWD.
# Falls back to $DATADOG_ROOT/dd-source if not inside a worktree.
function _dd_worktree
    set -l dir $PWD
    while test "$dir" != "/"
        if string match -qr '^dd-source' (basename $dir)
            echo $dir
            return
        end
        set dir (dirname $dir)
    end
    echo $DATADOG_ROOT/dd-source
end

# Shortcuts for monorepos
alias cddd='cd $DATADOG_ROOT'
function cdddsource; cd (_dd_worktree); end
function cddomains; cd (_dd_worktree)/domains; end
function cddomainsstreaming; cd (_dd_worktree)/domains/streaming; end
function cdlibstreamingrust; cd (_dd_worktree)/domains/streaming/shared/libs/libstreaming/rust; end
function cdstreamsskeletonrust; cd (_dd_worktree)/domains/streaming/apps/streams-skeleton-rust; end

# ukcl
function cdukcl; cd (_dd_worktree)/domains/kafka/libs/rust/client; end
function cdukclgo; cd (_dd_worktree)/domains/kafka/libs/go/client; end

# streaming-kafka-client
function cdstreamkc; cd (_dd_worktree)/domains/streaming/libs/rust/streaming_kafka_client; end
