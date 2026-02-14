import { Lock, Globe, Users, Plus, FolderOpen } from "lucide-react"
import Image from "next/image"

const albums = [
  { cover: "/images/photo-1.jpg", name: "Landscapes", count: 42, privacy: "public" },
  { cover: "/images/photo-2.jpg", name: "Pets", count: 18, privacy: "private" },
  { cover: "/images/photo-3.jpg", name: "City Life", count: 31, privacy: "shared" },
  { cover: "/images/photo-4.jpg", name: "Food", count: 24, privacy: "public" },
  { cover: "/images/photo-5.jpg", name: "Nature", count: 56, privacy: "private" },
  { cover: "/images/photo-6.jpg", name: "Macro", count: 13, privacy: "shared" },
]

const privacyIcon = {
  public: Globe,
  private: Lock,
  shared: Users,
}

const privacyBadge = {
  public: "badge-info",
  private: "badge-warning",
  shared: "badge-success",
}

export function AlbumsSection() {
  return (
    <section>
      <div className="flex items-end justify-between mb-8">
        <div>
          <h2 className="text-3xl font-serif font-bold text-base-content text-balance">Albums</h2>
          <p className="text-sm text-base-content/40 mt-1">6 albums</p>
        </div>
        <button className="btn btn-sm btn-accent gap-1.5 rounded-md">
          <Plus className="h-4 w-4" strokeWidth={1.5} />
          New Album
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {albums.map((album) => {
          const Icon = privacyIcon[album.privacy as keyof typeof privacyIcon]
          const badgeClass = privacyBadge[album.privacy as keyof typeof privacyBadge]
          return (
            <div key={album.name} className="group cursor-pointer">
              <figure className="relative aspect-[16/10] overflow-hidden rounded-md bg-base-300">
                <Image
                  src={album.cover}
                  alt={album.name}
                  fill
                  className="object-cover group-hover:scale-[1.03] transition-transform duration-500 ease-out"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-neutral/60 via-neutral/10 to-transparent" />
                <div className="absolute bottom-3 left-3 right-3 flex items-end justify-between">
                  <div>
                    <h3 className="text-base-100 font-serif font-semibold text-base">{album.name}</h3>
                    <p className="text-base-100/70 text-xs font-mono">{album.count} photos</p>
                  </div>
                  <span className={`badge badge-sm ${badgeClass} gap-1`}>
                    <Icon className="h-3 w-3" strokeWidth={1.5} />
                    {album.privacy}
                  </span>
                </div>
              </figure>
            </div>
          )
        })}
      </div>
    </section>
  )
}

export function EmptyAlbumState() {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="bg-base-300 rounded-full p-4 mb-4">
        <FolderOpen className="h-8 w-8 text-base-content/30" strokeWidth={1.5} />
      </div>
      <h3 className="text-lg font-serif font-semibold text-base-content mb-1">No albums yet</h3>
      <p className="text-sm text-base-content/40 mb-4 max-w-xs">
        Create your first album to start organizing your photos.
      </p>
      <button className="btn btn-accent btn-sm gap-1.5 rounded-md">
        <Plus className="h-4 w-4" strokeWidth={1.5} />
        Create Album
      </button>
    </div>
  )
}
