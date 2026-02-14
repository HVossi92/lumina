import { Users, Link2, Copy } from "lucide-react"

const sharedAlbums = [
  { name: "Trip to Iceland", people: 4, link: "snapvault.app/s/xK9m2" },
  { name: "Wedding 2025", people: 12, link: "snapvault.app/s/pQ7n1" },
]

export function SharedSection() {
  return (
    <section>
      <div className="mb-8">
        <h2 className="text-3xl font-serif font-bold text-base-content text-balance">Shared</h2>
        <p className="text-sm text-base-content/40 mt-1">2 shared albums</p>
      </div>
      <div className="flex flex-col gap-3">
        {sharedAlbums.map((album) => (
          <div key={album.name} className="flex items-center gap-4 bg-base-200 border border-base-300 rounded-md p-4">
            <div className="bg-base-300 rounded-md p-3">
              <Users className="h-5 w-5 text-base-content/40" strokeWidth={1.5} />
            </div>
            <div className="flex-1 min-w-0">
              <h3 className="text-sm font-medium text-base-content">{album.name}</h3>
              <p className="text-xs text-base-content/40">{album.people} people have access</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="hidden sm:flex items-center gap-1 bg-base-300 rounded-md px-3 py-1.5">
                <Link2 className="h-3 w-3 text-base-content/40" strokeWidth={1.5} />
                <span className="text-xs font-mono text-base-content/50">{album.link}</span>
              </div>
              <button className="btn btn-ghost btn-sm btn-square text-base-content/40 hover:text-base-content" aria-label="Copy link">
                <Copy className="h-4 w-4" strokeWidth={1.5} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
