import { Heart, Download, MoreHorizontal, Grid3X3, LayoutList, SlidersHorizontal } from "lucide-react"
import Image from "next/image"

const photos = [
  { src: "/images/photo-1.jpg", title: "Golden Hills", date: "Jan 12, 2026", fav: true },
  { src: "/images/photo-2.jpg", title: "Good Boy", date: "Jan 10, 2026", fav: false },
  { src: "/images/photo-3.jpg", title: "City Dusk", date: "Dec 28, 2025", fav: true },
  { src: "/images/photo-4.jpg", title: "Rustic Table", date: "Dec 15, 2025", fav: false },
  { src: "/images/photo-5.jpg", title: "Mountain Lake", date: "Nov 22, 2025", fav: false },
  { src: "/images/photo-6.jpg", title: "Butterfly", date: "Nov 10, 2025", fav: true },
]

export function PhotosSection() {
  return (
    <section>
      {/* Toolbar */}
      <div className="flex flex-wrap items-end justify-between gap-3 mb-8">
        <div>
          <h2 className="text-3xl font-serif font-bold text-base-content text-balance">All Photos</h2>
          <p className="text-sm text-base-content/40 mt-1">128 photos across 6 albums</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="join">
            <button className="join-item btn btn-sm btn-active" aria-label="Grid view">
              <Grid3X3 className="h-4 w-4" strokeWidth={1.5} />
            </button>
            <button className="join-item btn btn-sm" aria-label="List view">
              <LayoutList className="h-4 w-4" strokeWidth={1.5} />
            </button>
          </div>
          <button className="btn btn-sm btn-ghost gap-1.5 text-base-content/60">
            <SlidersHorizontal className="h-4 w-4" strokeWidth={1.5} />
            <span className="hidden sm:inline">Filter</span>
          </button>
        </div>
      </div>

      {/* Photo Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {photos.map((photo) => (
          <div
            key={photo.title}
            className="group cursor-pointer"
          >
            <figure className="relative aspect-[4/3] overflow-hidden rounded-md bg-base-300">
              <Image
                src={photo.src}
                alt={photo.title}
                fill
                className="object-cover group-hover:scale-[1.03] transition-transform duration-500 ease-out"
              />
              {/* Hover overlay */}
              <div className="absolute inset-0 bg-neutral/0 group-hover:bg-neutral/30 transition-colors duration-300" />
              <div className="absolute top-2.5 right-2.5 flex gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <button className="btn btn-xs btn-circle bg-base-100/80 border-none hover:bg-base-100 text-base-content" aria-label="Download">
                  <Download className="h-3 w-3" strokeWidth={1.5} />
                </button>
                <button className="btn btn-xs btn-circle bg-base-100/80 border-none hover:bg-base-100 text-base-content" aria-label="More">
                  <MoreHorizontal className="h-3 w-3" strokeWidth={1.5} />
                </button>
              </div>
              <button
                className={`absolute top-2.5 left-2.5 btn btn-xs btn-circle border-none transition-all duration-300 ${
                  photo.fav
                    ? "bg-accent text-accent-content"
                    : "bg-base-100/80 text-base-content opacity-0 group-hover:opacity-100"
                }`}
                aria-label={photo.fav ? "Unfavorite" : "Favorite"}
              >
                <Heart className={`h-3 w-3 ${photo.fav ? "fill-current" : ""}`} strokeWidth={1.5} />
              </button>
            </figure>
            <div className="pt-2.5 px-0.5">
              <h3 className="text-sm font-medium text-base-content">{photo.title}</h3>
              <p className="text-xs text-base-content/40 font-mono">{photo.date}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
